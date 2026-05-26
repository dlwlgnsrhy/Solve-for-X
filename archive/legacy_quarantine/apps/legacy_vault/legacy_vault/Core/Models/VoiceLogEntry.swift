import Foundation
import CoreData

// MARK: - VoiceLogEntry

struct VoiceLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var recordingDate: Date
    var transcript: String
    var aiSummary: String?
    var aiEnrichment: String?
    var sentiment: Int
    var durationMs: Int
    var audioURL: URL?
    var keywords: [String]

    var keywordsJSON: String {
        do {
            return try JSONEncoder().encode(keywords).iso8859_escaped()
        } catch {
            return "[]"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VoiceLogEntry, rhs: VoiceLogEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Helpers

private extension Data {
        func iso8859_bytes() -> [UInt8] {
        var result: [UInt8] = []
        self.withUnsafeBytes { rawBuffer in
            let bytes = rawBuffer.bindMemory(to: UInt8.self).baseAddress!
            for index in 0 ..< self.count {
                let byte = bytes[index]
                if byte < 128 {
                    result.append(byte)
                } else {
                    result.append(0x3F)
                }
            }
        }
        return result
    }
}

private extension Data {
        func iso8859_escaped() -> String {
        let bytes = iso8859_bytes()
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }
}
