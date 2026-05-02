import Foundation
import UserNotifications

@MainActor
final class NotificationHandler: ObservableObject {
    static let shared = NotificationHandler()
    
    @Published var notificationAuthorized: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    public init() {
        checkAuthorizationStatus()
    }
    
    /// Request notification permissions for ping alerts.
    func requestNotificationPermission() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus != .denied
            }
        }
        
        if #available(iOS 17.0, *) {
            center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                self?.checkAuthorizationStatus()
            }
        } else {
            center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                self?.checkAuthorizationStatus()
            }
        }
    }
    
    /// Schedule a daily ping reminder notification.
    func scheduleDailyPingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🔐 귀뚜라미 알림"
        content.body = "오늘의 귀뚜르미 ping을 잊지 마세요!"
        content.sound = .default
        
        // Trigger at 9:00 AM daily
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "dailyPingReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                print("Failed to schedule ping reminder: \(error)")
            }
        }
    }
    
    /// Clear all scheduled notifications.
    func clearAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    /// Check current authorization status.
    private func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }
        }
    }
}
