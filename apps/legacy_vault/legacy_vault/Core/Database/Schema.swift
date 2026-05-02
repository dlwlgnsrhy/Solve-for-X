import Foundation
import CoreData

// MARK: - CLCVoiceLogEntry (Core Data)

@objc(CLCVoiceLogEntry)
public final class CLCVoiceLogEntry: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var recordingDate: Date
    @NSManaged var transcript: String
    @NSManaged var aiSummary: String?
    @NSManaged var aiEnrichment: String?
    @NSManaged var sentiment: Int16
    @NSManaged var durationMs: Int32
    @NSManaged var audioURL: String?
    @NSManaged var keywordsJSON: String
}

// Extension: VoiceLogEntry (Swift struct) typealias for fetch types
extension CLCVoiceLogEntry {
    /// Convenience typealias matching the Swift model name for fetch request type annotations.
    typealias SwiftModel = VoiceLogEntry
}

extension CLCInheritanceContact {
    static func fetch() -> NSFetchRequest<CLCInheritanceContact> {
        CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
    }
}

public extension CLCVaultRecord {
    static func fetch() -> NSFetchRequest<CLCVaultRecord> {
        CLCVaultRecord.fetchRequest() as! NSFetchRequest<CLCVaultRecord>
    }
}

extension CLCChatMessage {
    static func fetch() -> NSFetchRequest<CLCChatMessage> {
        CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
    }
}

extension CLCValueKeyword {
    static func fetch() -> NSFetchRequest<CLCValueKeyword> {
        CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
    }
}

// MARK: - CLCVaultRecord (Core Data)

@objc(CLCVaultRecord)
public final class CLCVaultRecord: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var vaultType: String
    @NSManaged var encryptedData: Data
    @NSManaged var salt: Data
    @NSManaged var lastPingDate: Date
    @NSManaged var deadlineDays: Int32
    @NSManaged var targetEmails: String
    @NSManaged var status: String
}

// MARK: - CLCInheritanceContact (Core Data)

@objc(CLCInheritanceContact)
public final class CLCInheritanceContact: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var email: String
    @NSManaged var relationship: String
    @NSManaged var notificationStatus: Int16
}

// MARK: - CLCChatMessage (Core Data)

@objc(CLCChatMessage)
public final class CLCChatMessage: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var role: String
    @NSManaged var content: String
    @NSManaged var timestamp: Date
    @NSManaged var embeddingId: String?
}

// MARK: - CLCValueKeyword (Core Data)

@objc(CLCValueKeyword)
public final class CLCValueKeyword: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var word: String
    @NSManaged var frequency: Int32
    @NSManaged var firstOccurrence: Date
    @NSManaged var lastOccurrence: Date
    @NSManaged var category: String
}
