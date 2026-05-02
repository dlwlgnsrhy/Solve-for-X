import Foundation
import CoreData
import Accelerate

@MainActor
final class VectorDBService: ObservableObject {
    static let shared = VectorDBService()
    
    @Published var isIndexing: Bool = false
    
    private let databaseManager = DatabaseManager.shared
    private let embeddingService = EmbeddingService()
    
    enum VectorDBError: LocalizedError {
        case storeFailed
        case searchFailed
        case entityNotFound
        
        var errorDescription: String? {
            switch self {
            case .storeFailed: return "벡터 저장에 실패했습니다"
            case .searchFailed: return "벡터 검색에 실패했습니다"
            case .entityNotFound: return "관련 엔티티를 찾을 수 없습니다"
            }
        }
    }
    
    public init() {}
    
    /// Stores an embedding vector for a given entity.
    func storeEmbedding(for entityId: String, vector: [Float], metadata: String) async throws {
        isIndexing = true
        defer { isIndexing = false }
        
        // Store embedding metadata in ValueKeyword's embeddingId relation
        // sqlite-vec integration placeholder: Core Data will hold metadata
        // Actual vector storage requires sqlite-vec .dylib
        guard let entity = valueKeyword(for: entityId) else {
            throw VectorDBError.entityNotFound
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        entity.setValue(try encoder.encode(metadata), forKey: "embeddingId")
        
        try databaseManager.saveContext()
    }
    
    /// Searches for similar embeddings by a query text.
    /// Returns array of matching entity IDs, sorted by similarity.
    func searchSimilar(_ query: String, topK: Int = 5) async throws -> [(entityId: String, score: Float)] {
        isIndexing = true
        defer { isIndexing = false }
        
        let queryVector = try await embeddingService.generateEmbedding(for: query)
        
        // Placeholder: since sqlite-vec isn't loaded, do a text-based similarity fallback
        // In production: use sqlite-vec distance search
        
        // Fetch all ValueKeywords and match by text similarity
        let fetchRequest = CLCValueKeyword.fetch()
        let results = try databaseManager.mainContext.fetch(fetchRequest)
        
        var scores: [(entityId: String, score: Float)] = results.compactMap { keyword in
            let text = keyword.word
            let textVector = hashingVector(text: text)
            let score = cosineSimilarity(queryVector, textVector)
            guard abs(score) > 0.1 else { return nil }
            return (entityId: keyword.id, score: score)
        }
        
        scores.sort { $0.score > $1.score }
        return Array(scores.prefix(topK))
    }
    
    /// Cosine similarity between two vectors.
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, a.count > 0 else { return 0.0 }
        var dot = 0.0, magA = 0.0, magB = 0.0
        for i in 0..<a.count {
            dot += Double(a[i]) * Double(b[i])
            magA += Double(a[i]) * Double(a[i])
            magB += Double(b[i]) * Double(b[i])
        }
        let denom = sqrt(magA) * sqrt(magB)
        return denom > 0 ? Float(dot / denom) : 0.0
    }
    
    /// Hash-based vector for text comparison (placeholder for ML embeddings).
    private func hashingVector(text: String) -> [Float] {
        var vector = [Float](repeating: 0.0, count: 384)
        let encoded = text.data(using: .utf8) ?? Data()
        for i in 0..<min(encoded.count, 50) {
            let byte = encoded[i]
            let position = Int(byte) % 384
            vector[position] += Float(byte) / 255.0
        }
        let mag = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        if mag > 0 {
            vector = vector.map { $0 / mag }
        }
        return vector
    }
    
    private func valueKeyword(for entityId: String) -> CLCValueKeyword? {
        let request = CLCValueKeyword.fetch()
        request.predicate = NSPredicate(format: "id == %@", entityId)
        request.fetchLimit = 1
        return try? databaseManager.mainContext.fetch(request).first
    }
}
