import Foundation

struct ValueKeyword: Identifiable, Codable, Hashable {
    let id: UUID
    var word: String
    var frequency: Int
    var firstOccurrence: Date
    var lastOccurrence: Date
    var category: KeywordCategory

    enum KeywordCategory: String, Codable {
        case family, career, emotion, challenge, peace, growth
    }

        func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ValueKeyword, rhs: ValueKeyword) -> Bool {
        lhs.id == rhs.id
    }
}
