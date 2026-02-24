import Foundation
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol StorageService: Sendable {
    func saveCampaign(_ data: [String: String])
    func saveNavigation(_ data: [String: String])
    func saveEndpoint(_ url: String)
    func saveMode(_ mode: String)
    func markFirstTimeDone()
    func savePermission(allowed: Bool, denied: Bool)
    func loadAll() -> LoadedData
}

struct LoadedData: Sendable {
    var campaign: [String: String]
    var navigation: [String: String]
    var settings: Settings
    var permission: Permission
    
    struct Settings: Sendable {
        var endpoint: String?
        var mode: String?
        var isFirstTime: Bool
    }
    
    struct Permission: Sendable {
        var allowed: Bool
        var denied: Bool
        var askedAt: Date?
    }
}

final class DiskStorage: StorageService {
    
    private let vault = UserDefaults(suiteName: "group.stats.vault")!
    private let cache = UserDefaults.standard
    private var quick: [String: Any] = [:]
    
    // UNIQUE: sm_ prefix
    private enum Key {
        static let campaign = "sm_campaign_payload"
        static let navigation = "sm_navigation_payload"
        static let endpoint = "sm_endpoint_primary"
        static let mode = "sm_mode_active"
        static let firstTime = "sm_first_time_flag"
        static let permAllowed = "sm_perm_allowed"
        static let permDenied = "sm_perm_denied"
        static let permDate = "sm_perm_date"
    }
    
    init() {
        preload()
    }
    
    func saveCampaign(_ data: [String: String]) {
        if let json = toJSON(data) {
            vault.set(json, forKey: Key.campaign)
            quick[Key.campaign] = json
        }
    }
    
    func saveNavigation(_ data: [String: String]) {
        if let json = toJSON(data) {
            let masked = mask(json)
            vault.set(masked, forKey: Key.navigation)
        }
    }
    
    func saveEndpoint(_ url: String) {
        vault.set(url, forKey: Key.endpoint)
        cache.set(url, forKey: Key.endpoint)
        quick[Key.endpoint] = url
    }
    
    func saveMode(_ mode: String) {
        vault.set(mode, forKey: Key.mode)
    }
    
    func markFirstTimeDone() {
        vault.set(true, forKey: Key.firstTime)
    }
    
    func savePermission(allowed: Bool, denied: Bool) {
        vault.set(allowed, forKey: Key.permAllowed)
        vault.set(denied, forKey: Key.permDenied)
        vault.set(Date().timeIntervalSince1970 * 1000, forKey: Key.permDate)
    }
    
    func loadAll() -> LoadedData {
        var campaign: [String: String] = [:]
        if let json = quick[Key.campaign] as? String ?? vault.string(forKey: Key.campaign),
           let dict = fromJSON(json) {
            campaign = dict
        }
        
        var navigation: [String: String] = [:]
        if let masked = vault.string(forKey: Key.navigation),
           let json = unmask(masked),
           let dict = fromJSON(json) {
            navigation = dict
        }
        
        let endpoint = quick[Key.endpoint] as? String 
                    ?? vault.string(forKey: Key.endpoint) 
                    ?? cache.string(forKey: Key.endpoint)
        
        let mode = vault.string(forKey: Key.mode)
        let isFirstTime = !vault.bool(forKey: Key.firstTime)
        
        let allowed = vault.bool(forKey: Key.permAllowed)
        let denied = vault.bool(forKey: Key.permDenied)
        let ts = vault.double(forKey: Key.permDate)
        let askedAt = ts > 0 ? Date(timeIntervalSince1970: ts / 1000) : nil
        
        return LoadedData(
            campaign: campaign,
            navigation: navigation,
            settings: LoadedData.Settings(
                endpoint: endpoint,
                mode: mode,
                isFirstTime: isFirstTime
            ),
            permission: LoadedData.Permission(
                allowed: allowed,
                denied: denied,
                askedAt: askedAt
            )
        )
    }
    
    private func preload() {
        if let endpoint = vault.string(forKey: Key.endpoint) {
            quick[Key.endpoint] = endpoint
        }
    }
    
    private func toJSON(_ data: [String: String]) -> String? {
        let anyDict = data.mapValues { $0 as Any }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: anyDict),
              let string = String(data: jsonData, encoding: .utf8) else { return nil }
        return string
    }
    
    private func fromJSON(_ string: String) -> [String: String]? {
        guard let data = string.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        var result: [String: String] = [:]
        for (key, value) in dict {
            result[key] = "\(value)"
        }
        return result
    }
    
    private func mask(_ string: String) -> String {
        Data(string.utf8).base64EncodedString()
            .replacingOccurrences(of: "=", with: "{")
            .replacingOccurrences(of: "+", with: "}")
    }
    
    private func unmask(_ string: String) -> String? {
        let base64 = string
            .replacingOccurrences(of: "{", with: "=")
            .replacingOccurrences(of: "}", with: "+")
        
        guard let data = Data(base64Encoded: base64),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

// MARK: - Network Service

protocol NetworkService: Sendable {
    func validateFirebase() async throws -> Bool
    func fetchCampaign(deviceID: String) async throws -> [String: String]
    func fetchEndpoint(campaign: [String: Any]) async throws -> String
}

final class HTTPService: NetworkService {
    
    private let client: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        
        self.client = URLSession(configuration: config)
    }
    
    func validateFirebase() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Database.database().reference().child("users/log/data")
                .observeSingleEvent(of: .value) { snapshot in
                    if let url = snapshot.value as? String,
                       !url.isEmpty,
                       URL(string: url) != nil {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func fetchCampaign(deviceID: String) async throws -> [String: String] {
        let base = "https://gcdsdk.appsflyer.com/install_data/v4.0"
        let app = "id\(Settings.appID)"
        
        var builder = URLComponents(string: "\(base)/\(app)")
        builder?.queryItems = [
            URLQueryItem(name: "devkey", value: Settings.devKey),
            URLQueryItem(name: "device_id", value: deviceID)
        ]
        
        guard let url = builder?.url else {
            throw ServiceError.badURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await client.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.failed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ServiceError.decode
        }
        
        var result: [String: String] = [:]
        for (key, value) in json {
            result[key] = "\(value)"
        }
        return result
    }
    
    private var userAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    func fetchEndpoint(campaign: [String: Any]) async throws -> String {
        guard let url = URL(string: "https://homeinventtorymaster.com/config.php") else {
            throw ServiceError.badURL
        }
        
        var payload: [String: Any] = campaign
        payload["os"] = "iOS"
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        payload["store_id"] = "id\(Settings.appID)"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        var lastError: Error?
        let retries: [Double] = [8.0, 16.0, 32.0]
        
        for (index, delay) in retries.enumerated() {
            do {
                let (data, response) = try await client.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.failed
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let success = json["ok"] as? Bool,
                          success,
                          let endpoint = json["url"] as? String else {
                        throw ServiceError.decode
                    }
                    
                    return endpoint
                } else if httpResponse.statusCode == 429 {
                    let backoff = delay * Double(index + 1)
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                    continue
                } else {
                    throw ServiceError.failed
                }
            } catch {
                lastError = error
                if index < retries.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ServiceError.failed
    }
}

enum ServiceError: Error {
    case badURL
    case failed
    case decode
}

