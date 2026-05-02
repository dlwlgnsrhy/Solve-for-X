import Foundation
import CoreData
import UserNotifications

@MainActor
final class DeadManSwitchService: ObservableObject {
    static let shared = DeadManSwitchService()
    
    @Published var isConfigured: Bool = false
    @Published var remainingDays: Int = 0
    @Published var status: DeadManStatus = .idle
    @Published var contacts: [CLCInheritanceContact] = []
    @Published var vaults: [CLCVaultRecord] = []
    
    private let databaseManager = DatabaseManager.shared
    
    enum DeadManStatus: String, CaseIterable, Codable {
        case idle = "idle"
        case waiting = "waiting"
        case alert = "alert"
        case triggered = "triggered"
        case disabled = "disabled"
    }
    
    public init() {
        loadConfig()
        checkStatus()
    }
    

    func configure(heirs: [CLCInheritanceContact], deadlineDays: Int, vaultRecords: [CLCVaultRecord]) async throws {

        for contact in heirs {
            let entity = createEntity(CLCInheritanceContact.self)
            entity.id = contact.id
            entity.name = contact.name
            entity.email = contact.email
            entity.relationship = contact.relationship
            entity.notificationStatus = contact.notificationStatus
        }
        

        for vault in vaultRecords {
            let entity = createEntity(CLCVaultRecord.self)
            entity.id = vault.id
            entity.name = vault.name
            entity.vaultType = vault.vaultType
            entity.encryptedData = vault.encryptedData
            entity.salt = vault.salt
            entity.lastPingDate = vault.lastPingDate
            entity.deadlineDays = vault.deadlineDays
            entity.targetEmails = vault.targetEmails
            entity.status = vault.status
        }
        
        isConfigured = true
        remainingDays = deadlineDays
        status = .waiting
        
        try databaseManager.saveContext()
    }
    
    /// Called periodically (e.g., daily) to check if user is still alive.
    func checkStatus() {
        guard isConfigured else { return }
        
        let deadline = Calendar.current.date(byAdding: .day, value: remainingDays, to: Date()) ?? Date()
        let now = Date()
        
        if now > deadline {
            status = .triggered
            sendNotifications()
        } else if now > Calendar.current.date(byAdding: .day, value: -3, to: deadline) ?? Date() {
            status = .alert
        } else {
            status = .waiting
        }
    }
    
    func pingAlive() {
        status = .waiting
        remainingDays = getDeadlineDays()
        
        let fetch = CLCVaultRecord.fetch()
        fetch.sortDescriptors = [NSSortDescriptor(key: "lastPingDate", ascending: false)]
        fetch.fetchLimit = 1
        
        if let record = try? databaseManager.mainContext.fetch(fetch).first {
            record.lastPingDate = Date()
            try? databaseManager.saveContext()
        }
    }
    
    /// Disable the dead man switch entirely.
    func disableSwitch() {
        isConfigured = false
        status = .disabled
    }
    
    /// Load configuration from Core Data.
    private func loadConfig() {
        let fetch = CLCInheritanceContact.fetch()
        contacts = (try? databaseManager.mainContext.fetch(fetch)) ?? []
        
        let vaultFetch = CLCVaultRecord.fetch()
        vaults = (try? databaseManager.mainContext.fetch(vaultFetch)) ?? []
        
        isConfigured = !contacts.isEmpty && !vaults.isEmpty
        remainingDays = getDeadlineDays()
    }
    
    /// Get configured deadline days (default 7 if not stored).
    private func getDeadlineDays() -> Int {
        if let first = vaults.first {
            return Int(first.deadlineDays)
        }
        return 7
    }
    
    private func sendNotifications() {
        let center = UNUserNotificationCenter.current()
        for contact in contacts where contact.email.contains("@") {
            let content = UNMutableNotificationContent()
            content.title = "🚨 Guardian Alarm"
            content.body = "Heir activation triggered by inactivity"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let id = UUID(uuidString: contact.id) ?? UUID()
            let request = UNNotificationRequest(identifier: "guardian_\(id.uuidString)", content: content, trigger: trigger)
            center.add(request)
        }
        let emails = contacts.map(\.email).filter { !$0.isEmpty }
        if !emails.isEmpty {
            print("Would notify heirs: \(emails.joined(separator: ", "))")
        }
    }
    
    // MARK: - Entity Creation Helpers
    
    private func createEntity<T: NSManagedObject>(_ type: T.Type) -> T {
        let context = databaseManager.mainContext
        return NSEntityDescription.insertNewObject(forEntityName: String(describing: type), into: context) as! T
    }
}
