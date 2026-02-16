import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleWarrantyNotification(for item: Item, daysBefore: Int) {
        guard let warrantyDate = item.warrantyEndDate,
              !item.isLifetimeWarranty,
              let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: warrantyDate),
              notificationDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Warranty Expiring Soon"
        content.body = "\(item.name) warranty expires in \(daysBefore) days"
        content.sound = .default
        content.categoryIdentifier = "WARRANTY_REMINDER"
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "warranty_\(item.id.uuidString)_\(daysBefore)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleMaintenanceNotification(for task: MaintenanceTask, itemName: String) {
        guard let nextDue = task.nextDueDate,
              nextDue > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Maintenance Due"
        content.body = "\(task.name) for \(itemName) is due"
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE_REMINDER"
        
        let components = Calendar.current.dateComponents([.year, .month, .day], from: nextDue)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "maintenance_\(task.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling maintenance notification: \(error)")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
