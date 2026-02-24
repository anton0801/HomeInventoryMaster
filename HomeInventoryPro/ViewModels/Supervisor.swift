import Foundation
import Combine
import UIKit
import UserNotifications
import Network
import AppsFlyerLib

@MainActor
final class Supervisor: ObservableObject {
    
    // MARK: - Actors
    private let stateActor = StateActor()
    private let dataActor = DataActor()
    private let permissionActor = PermissionActor()
    private let uiActor = UIActor()
    
    // MARK: - Published State (for SwiftUI)
    @Published private(set) var phase: StateActor.Phase = .startup
    @Published var uiFlags: UIActor.Flags = UIActor.Flags(
        showPermissionDialog: false,
        showOfflineScreen: false,
        navigateMain: false,
        navigateWeb: false
    )
    
    // MARK: - Services
    private let storage: StorageService
    private let network: NetworkService
    
    // MARK: - Control
    private var timeoutTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    
    init() {
        self.storage = DiskStorage()
        self.network = HTTPService()
        
        setupNetworkMonitor()
    }
    
    func send(_ message: ActorMessage) async {
        
        await processMessage(message)
        
        await updatePublishedState()
    }
    
    // MARK: - Process Message
    private func processMessage(_ message: ActorMessage) async {
        switch message {
        case .initialize:
            await stateActor.setPhase(.preparing)
            await loadPersistedData()
            scheduleTimeout()
            
        case .timeout:
            let locked = await stateActor.isLocked()
            if !locked {
                await stateActor.setPhase(.stopped)
                await uiActor.setNavigateMain(true)
            }
            
        case .campaignReceived(let data):
            await dataActor.setCampaign(DataActor.CampaignData(values: data))
            storage.saveCampaign(data)
            await send(.validateStart)
            
        case .navigationReceived(let data):
            await dataActor.setNavigation(DataActor.NavigationData(values: data))
            storage.saveNavigation(data)
            
        case .networkOnline:
            let locked = await stateActor.isLocked()
            let phase = await stateActor.getPhase()
            if !locked, case .disconnected = phase {
                await stateActor.setPhase(.stopped)
                await uiActor.setShowOfflineScreen(false)
            }
            
        case .networkOffline:
            let locked = await stateActor.isLocked()
            if !locked {
                await stateActor.setPhase(.disconnected)
                await uiActor.setShowOfflineScreen(true)
            }
            
        case .validateStart:
            await stateActor.setPhase(.checking)
            await performValidation()
            
        case .validateSuccess:
            await stateActor.setPhase(.checked)
            await executeBusinessLogic()
            
        case .validateFailure:
            await stateActor.setPhase(.stopped)
            await uiActor.setNavigateMain(true)
            
        case .fetchCampaignStart:
            await performCampaignFetch()
            
        case .fetchCampaignSuccess(let data):
            await dataActor.setCampaign(DataActor.CampaignData(values: data))
            storage.saveCampaign(data)
            await send(.fetchEndpointStart)
            
        case .fetchCampaignFailure:
            await stateActor.setPhase(.stopped)
            await uiActor.setNavigateMain(true)
            
        case .fetchEndpointStart:
            await performEndpointFetch()
            
        case .fetchEndpointSuccess(let url):
            await stateActor.complete(url: url)
            await dataActor.updateSettings(endpoint: url, mode: "Active", isFirstTime: false)
            storage.saveEndpoint(url)
            storage.saveMode("Active")
            storage.markFirstTimeDone()
            
            timeoutTask?.cancel()
            
            let permission = await permissionActor.getNotification()
            if permission.canAsk {
                await uiActor.setShowPermissionDialog(true)
            } else {
                await uiActor.setNavigateWeb(true)
            }
            
        case .fetchEndpointFailure:
            let settings = await dataActor.getSettings()
            if let saved = settings.endpoint {
                await stateActor.complete(url: saved)
                
                timeoutTask?.cancel()
                
                let permission = await permissionActor.getNotification()
                if permission.canAsk {
                    await uiActor.setShowPermissionDialog(true)
                } else {
                    await uiActor.setNavigateWeb(true)
                }
            } else {
                await stateActor.setPhase(.stopped)
                await uiActor.setNavigateMain(true)
            }
            
        case .permissionRequested:
            requestPermission()
            
        case .permissionAllowed:
            await permissionActor.setNotification(allowed: true, denied: false, askedAt: Date())
            storage.savePermission(allowed: true, denied: false)
            UIApplication.shared.registerForRemoteNotifications()
            await uiActor.setShowPermissionDialog(false)
            await uiActor.setNavigateWeb(true)
            
        case .permissionDenied:
            await permissionActor.setNotification(allowed: false, denied: true, askedAt: Date())
            storage.savePermission(allowed: false, denied: true)
            await uiActor.setShowPermissionDialog(false)
            await uiActor.setNavigateWeb(true)
            
        case .permissionSkipped:
            await permissionActor.markAsked()
            storage.savePermission(allowed: false, denied: false)
            await uiActor.setShowPermissionDialog(false)
            await uiActor.setNavigateWeb(true)  // ✅ ДОБАВЛЕНО!
            
        case .navigateToMain:
            await uiActor.setNavigateMain(true)
            
        case .navigateToWeb:
            await uiActor.setNavigateWeb(true)
        }
    }
    
    // MARK: - Business Logic
    
    private func loadPersistedData() async {
        let loaded = storage.loadAll()
        
        await dataActor.setCampaign(DataActor.CampaignData(values: loaded.campaign))
        await dataActor.setNavigation(DataActor.NavigationData(values: loaded.navigation))
        await dataActor.updateSettings(
            endpoint: nil,  // ✅ ВСЕГДА nil для бизнес-логики!
            mode: loaded.settings.mode,
            isFirstTime: loaded.settings.isFirstTime
        )
        await permissionActor.setNotification(
            allowed: loaded.permission.allowed,
            denied: loaded.permission.denied,
            askedAt: loaded.permission.askedAt
        )
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            await send(.timeout)
        }
    }
    
    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if path.status == .satisfied {
                    await self.send(.networkOnline)
                } else {
                    await self.send(.networkOffline)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
    private func performValidation() async {
        do {
            let isValid = try await network.validateFirebase()
            
            if isValid {
                await send(.validateSuccess)
            } else {
                await send(.validateFailure)
            }
        } catch {
            await send(.validateFailure)
        }
    }
    
    private func executeBusinessLogic() async {
        let campaign = await dataActor.getCampaign()
        
        guard campaign.hasValues else {
            let settings = await dataActor.getSettings()
            if let saved = settings.endpoint {
                await send(.fetchEndpointSuccess(saved))
            } else {
                await send(.navigateToMain)
            }
            return
        }
        
        if let temp = UserDefaults.standard.string(forKey: "temp_url") {
            await send(.fetchEndpointSuccess(temp))
            return
        }
        
        let settings = await dataActor.getSettings()
        if settings.isFirstTime && campaign.isOrganic {
            await send(.fetchCampaignStart)
            return
        }
        
        await send(.fetchEndpointStart)
    }
    
    private func performCampaignFetch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            let fetched = try await network.fetchCampaign(deviceID: deviceID)
            
            let navigation = await dataActor.getNavigation()
            var merged: [String: String] = fetched
            
            for (key, value) in navigation.values {
                if merged[key] == nil {
                    merged[key] = value
                }
            }
            
            await send(.fetchCampaignSuccess(merged))
        } catch {
            await send(.fetchCampaignFailure)
        }
    }
    
    private func performEndpointFetch() async {
        do {
            let campaign = await dataActor.getCampaign()
            let endpoint = try await network.fetchEndpoint(campaign: convertToAnyDict(campaign.values))
            
            await send(.fetchEndpointSuccess(endpoint))
        } catch {
            await send(.fetchEndpointFailure)
        }
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if granted {
                    await self.send(.permissionAllowed)
                } else {
                    await self.send(.permissionDenied)
                }
            }
        }
    }
    
    // MARK: - Update Published State
    private func updatePublishedState() async {
        phase = await stateActor.getPhase()
        uiFlags = await uiActor.getFlags()
    }
    
    // MARK: - Helpers
    private func convertToAnyDict(_ dict: [String: String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
        }
        return result
    }
}
