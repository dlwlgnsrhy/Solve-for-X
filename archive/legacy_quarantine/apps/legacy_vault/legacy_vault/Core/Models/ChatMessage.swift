import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var embeddingId: UUID?

    enum MessageRole: String, Codable {
        case user, assistant
    }

        func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
