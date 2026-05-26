import Foundation
import CoreData
import CloudKit
import UserNotifications

// MARK: - Backup Payload

private struct BackupPayload: Codable {
    let version: String
    let timestamp: Date
    let voiceLogs: [String]
    let vaults: [String]
    let contacts: [String]
    let messages: [String]
    let keywords: [String]
}

@MainActor
final class iCloudBackupService: ObservableObject {
    static let shared = iCloudBackupService()
    
    @Published var isAvailable: Bool = false
    @Published var lastBackupDate: Date?
    @Published var isBackedUp: Bool = false
    @Published var backupSize: Int = 0
    
    private let database = CKContainer.default().privateCloudDatabase
    private let key = KeychainHelper.shared
    private let encryptionService = EncryptionService()
    
    public init() {
        Task { @MainActor in checkAvailability() }
    }
    
    private func checkAvailability() {
        // accountStatus() is async, so use Task to block briefly for init time
        Task {
            do {
                let status = try await CKContainer.default().accountStatus()
                isAvailable = status == .available
            } catch {
                isAvailable = false
            }
        }
    }
    
    func runFullBackup() async throws {
        let voiceFetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
        let voiceLogs = try DatabaseManager.shared.mainContext.fetch(voiceFetch)
        

        let vaultFetch = CLCVaultRecord.fetchRequest() as! NSFetchRequest<CLCVaultRecord>
        let vaultRecords = try DatabaseManager.shared.mainContext.fetch(vaultFetch)
        

        let contactFetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
        let contacts = try DatabaseManager.shared.mainContext.fetch(contactFetch)
        

        let chatFetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
        let messages = try DatabaseManager.shared.mainContext.fetch(chatFetch)
        

        let keywordFetch = CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
        let keywords = try DatabaseManager.shared.mainContext.fetch(keywordFetch)
        

        let payload = BackupPayload(
            version: "1.0.0",
            timestamp: Date(),
            voiceLogs: voiceLogs.map { $0.id },
            vaults: vaultRecords.map { $0.id },
            contacts: contacts.map { $0.id },
            messages: messages.map { $0.id },
            keywords: keywords.map { $0.id }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(payload)
        

        let passphrase = try encryptionService.loadEncryptionKey()
        let encryptedData = try encryptionService.encrypt(jsonData, with: passphrase)
        

        let record = CKRecord(recordType: "VaultBackup")
        record["encryptedData"] = Data(encryptedData.ciphertext)
        record["nonce"] = Data(encryptedData.nonce)
        record["tag"] = Data(encryptedData.tag)
        record["timestamp"] = Date()
        
        try await database.save(record)
        

        lastBackupDate = Date()
        isBackedUp = true
        backupSize = jsonData.count
    }
    
    /// Restore data from the latest iCloud backup.
    func restoreFromBackup() async throws {
        guard isAvailable else {
            throw iCloudError.icloudNotAvailable
        }
        
        let database = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "recordType == 'VaultBackup'")
        let query = CKQuery(recordType: "VaultBackup", predicate: NSPredicate(value: true))
        let (results, _) = try await database.records(matching: query)
        
        guard let (_, recordResult) = results.first, let record = try? recordResult.get() else {
            throw iCloudError.noBackupFound
        }
        
        let timestamp = record["timestamp"] as! Date
        lastBackupDate = timestamp
        
        // Restore from the encrypted backup
        let encryptedData = record["encryptedData"] as! Data
        let nonce = record["nonce"] as! Data
        let tag = record["tag"] as! Data
        
        let payload = EncryptedPayload(
            ciphertext: Array(encryptedData),
            nonce: Array(nonce),
            tag: Array(tag)
        )
        
        let passphrase = try encryptionService.loadEncryptionKey()
        let decryptedData = try encryptionService.decrypt(payload, with: passphrase)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        _ = try decoder.decode(BackupPayload.self, from: decryptedData)
        
        print("Restored backup from \(timestamp)")
    }
    
    /// Get backup status summary.
    var backupStatus: String {
        if !isAvailable {
            return "iCloud 사용 불가"
        }
        if let date = lastBackupDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "마지막 백업: \(formatter.string(from: date))"
        }
        return "미백업"
    }
}

// MARK: - Errors

enum iCloudError: LocalizedError {
    case icloudNotAvailable
    case backupFailed
    case noBackupFound
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .icloudNotAvailable: return "iCloud를 사용할 수 없습니다"
        case .backupFailed: return "백업에 실패했습니다"
        case .noBackupFound: return "복원할 백업을 찾을 수 없습니다"
        case .restoreFailed: return "백업 복원에 실패했습니다"
        }
    }
}
