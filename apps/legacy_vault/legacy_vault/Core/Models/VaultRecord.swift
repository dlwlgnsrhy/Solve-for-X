import Foundation

struct VaultRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var vaultType: VaultType
    var encryptedData: Data
    var salt: Data
    var lastPingDate: Date
    var deadlineDays: Int
    var targetEmails: [String]
    var status: VaultStatus

    enum VaultType: String, Codable {
        case passwords, legal, financial, photos, videos, custom
    }

    enum VaultStatus: String, Codable {
        case active, paused, expired, alert_sent
    }

    init(fromCLC clc: CLCVaultRecord) {
        self.id = UUID(uuidString: clc.id) ?? UUID()
        self.name = clc.name
        self.vaultType = VaultType(rawValue: clc.vaultType) ?? .custom
        self.encryptedData = clc.encryptedData
        self.salt = clc.salt
        self.lastPingDate = clc.lastPingDate
        self.deadlineDays = Int(clc.deadlineDays)
        self.targetEmails = clc.targetEmails.components(separatedBy: ",").filter { !$0.isEmpty }
        self.status = VaultStatus(rawValue: clc.status) ?? .active
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VaultRecord, rhs: VaultRecord) -> Bool {
        lhs.id == rhs.id
    }
}
