import Foundation
import Combine

actor StateActor {
    
    // UNIQUE: App state
    private var phase: Phase = .startup
    private var endpoint: String?
    private var locked: Bool = false
    
    enum Phase {
        case startup
        case preparing
        case checking
        case checked
        case running(String)
        case stopped
        case disconnected
    }
    
    func getPhase() -> Phase {
        phase
    }
    
    func getEndpoint() -> String? {
        endpoint
    }
    
    func isLocked() -> Bool {
        locked
    }
    
    func setPhase(_ newPhase: Phase) {
        phase = newPhase
    }
    
    func setEndpoint(_ url: String) {
        endpoint = url
    }
    
    func lock() {
        locked = true
    }
    
    func complete(url: String) {
        endpoint = url
        phase = .running(url)
        locked = true
    }
}

actor DataActor {
    
    private var campaign: CampaignData = .empty
    private var navigation: NavigationData = .empty
    private var settings: SettingsData = .initial
    
    struct CampaignData: Sendable {
        let values: [String: String]
        
        var hasValues: Bool { !values.isEmpty }
        var isOrganic: Bool { values["af_status"] == "Organic" }
        
        static var empty: CampaignData {
            CampaignData(values: [:])
        }
    }
    
    struct NavigationData: Sendable {
        let values: [String: String]
        
        var hasValues: Bool { !values.isEmpty }
        
        static var empty: NavigationData {
            NavigationData(values: [:])
        }
    }
    
    struct SettingsData: Sendable {
        var endpoint: String?
        var mode: String?
        var isFirstTime: Bool
        
        static var initial: SettingsData {
            SettingsData(endpoint: nil, mode: nil, isFirstTime: true)
        }
    }
    
    func getCampaign() -> CampaignData {
        campaign
    }
    
    func getNavigation() -> NavigationData {
        navigation
    }
    
    func getSettings() -> SettingsData {
        settings
    }
    
    func setCampaign(_ data: CampaignData) {
        campaign = data
    }
    
    func setNavigation(_ data: NavigationData) {
        navigation = data
    }
    
    func updateSettings(endpoint: String?, mode: String?, isFirstTime: Bool?) {
        if let endpoint = endpoint {
            settings.endpoint = endpoint
        }
        if let mode = mode {
            settings.mode = mode
        }
        if let isFirstTime = isFirstTime {
            settings.isFirstTime = isFirstTime
        }
    }
}

actor PermissionActor {
    
    private var notification: NotificationState = .initial
    
    struct NotificationState: Sendable {
        var allowed: Bool
        var denied: Bool
        var askedAt: Date?
        
        var canAsk: Bool {
            guard !allowed && !denied else { return false }
            
            if let date = askedAt {
                let elapsed = Date().timeIntervalSince(date) / 86400
                return elapsed >= 3
            }
            return true
        }
        
        static var initial: NotificationState {
            NotificationState(allowed: false, denied: false, askedAt: nil)
        }
    }
    
    func getNotification() -> NotificationState {
        notification
    }
    
    func setNotification(allowed: Bool, denied: Bool, askedAt: Date? = nil) {
        notification = NotificationState(
            allowed: allowed,
            denied: denied,
            askedAt: askedAt ?? notification.askedAt
        )
    }
    
    func markAsked() {
        notification.askedAt = Date()
    }
}

actor UIActor {
    
    private var showPermissionDialog: Bool = false
    private var showOfflineScreen: Bool = false
    private var navigateMain: Bool = false
    private var navigateWeb: Bool = false
    
    func getFlags() -> Flags {
        Flags(
            showPermissionDialog: showPermissionDialog,
            showOfflineScreen: showOfflineScreen,
            navigateMain: navigateMain,
            navigateWeb: navigateWeb
        )
    }
    
    struct Flags: Sendable {
        var showPermissionDialog: Bool
        var showOfflineScreen: Bool
        var navigateMain: Bool
        var navigateWeb: Bool
    }
    
    // MARK: - Commands
    
    func setShowPermissionDialog(_ value: Bool) {
        showPermissionDialog = value
    }
    
    func setShowOfflineScreen(_ value: Bool) {
        showOfflineScreen = value
    }
    
    func setNavigateMain(_ value: Bool) {
        navigateMain = value
    }
    
    func setNavigateWeb(_ value: Bool) {
        navigateWeb = value
    }
}
