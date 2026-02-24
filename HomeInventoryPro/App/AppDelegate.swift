import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

struct Settings {
    static let appID = "6759264379"
    static let devKey = "pzbt8YAdZcaEKdeNoHovfC"
}

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    private let campaignBroker = CampaignBroker()
    private let pushBroker = PushBroker()
    private var trackingBroker: TrackingBroker?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        campaignBroker.onCampaign = { [weak self] in self?.broadcastCampaign($0) }
        campaignBroker.onNavigation = { [weak self] in self?.broadcastNavigation($0) }
        trackingBroker = TrackingBroker(broker: campaignBroker)
        
        setupFirebase()
        setupPush()
        setupTracking()
        
        if let notif = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushBroker.handle(notif: notif)
        }
        
        observe()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupPush() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func setupTracking() {
        trackingBroker?.configure()
    }
    
    private func observe() {
        NotificationCenter.default.addObserver(self, selector: #selector(activate), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func activate() {
        trackingBroker?.start()
    }
    
    private func broadcastCampaign(_ data: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
        }
    }
    
    private func broadcastNavigation(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token = token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.stats.vault")?.set(token, forKey: "shared_token")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "fcm_time")
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushBroker.handle(notif: notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushBroker.handle(notif: response.notification.request.content.userInfo)
        completionHandler()
    }
}

final class CampaignBroker: NSObject {
    var onCampaign: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    
    private var campaignBuf: [AnyHashable: Any] = [:]
    private var navigationBuf: [AnyHashable: Any] = [:]
    private var timer: Timer?
    private let key = "sm_campaign_merged"
    
    func receiveCampaign(_ data: [AnyHashable: Any]) {
        campaignBuf = data
        scheduleTimer()
        if !navigationBuf.isEmpty { merge() }
    }
    
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !isMerged() else { return }
        navigationBuf = data
        onNavigation?(data)
        timer?.invalidate()
        if !campaignBuf.isEmpty { merge() }
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() }
    }
    
    private func merge() {
        var result = campaignBuf
        navigationBuf.forEach { k, v in
            let newK = "deep_\(k)"
            if result[newK] == nil { result[newK] = v }
        }
        onCampaign?(result)
    }
    
    private func isMerged() -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}

final class PushBroker: NSObject {
    func handle(notif: [AnyHashable: Any]) {
        guard let url = extract(from: notif) else { return }
        UserDefaults.standard.set(url, forKey: "temp_url")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "temp_url_time")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            NotificationCenter.default.post(name: Notification.Name("LoadTempURL"), object: nil, userInfo: ["temp_url": url])
        }
    }
    
    private func extract(from payload: [AnyHashable: Any]) -> String? {
        if let url = payload["url"] as? String { return url }
        if let data = payload["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any], let data = aps["data"] as? [String: Any], let url = data["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any], let url = custom["target_url"] as? String { return url }
        return nil
    }
}

final class TrackingBroker: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var broker: CampaignBroker
    
    init(broker: CampaignBroker) {
        self.broker = broker
    }
    
    func configure() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Settings.devKey
        sdk.appleAppID = Settings.appID
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
    }
    
    func start() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "att_time")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        broker.receiveCampaign(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        var data: [AnyHashable: Any] = [:]
        data["error"] = true
        data["error_msg"] = error.localizedDescription
        broker.receiveCampaign(data)
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let deepLink = result.deepLink else { return }
        broker.receiveNavigation(deepLink.clickEvent)
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushBroker.handle(notif: userInfo)
        completionHandler(.newData)
    }
}
