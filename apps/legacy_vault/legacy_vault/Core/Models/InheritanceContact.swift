import Foundation

struct InheritanceContact: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var relationship: Relationship
    var notificationStatus: Int

    enum Relationship: String, Codable {
        case spouse, child, friend, organization
    }

    init(fromCLC clc: CLCInheritanceContact) {
        self.id = UUID(uuidString: clc.id) ?? UUID()
        self.name = clc.name
        self.email = clc.email
        self.relationship = Relationship(rawValue: clc.relationship) ?? .friend
        self.notificationStatus = Int(clc.notificationStatus)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InheritanceContact, rhs: InheritanceContact) -> Bool {
        lhs.id == rhs.id
    }
}
