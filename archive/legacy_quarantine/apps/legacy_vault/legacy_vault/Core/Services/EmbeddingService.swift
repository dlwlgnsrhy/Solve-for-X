import Foundation
import CoreML
import Accelerate

@MainActor
final class EmbeddingService: ObservableObject {
    static let shared = EmbeddingService()
    
    @Published var isGenerating: Bool = false
    
    private let embeddingDimension: Int = 384
    
    enum EmbeddingError: LocalizedError {
        case modelLoadFailed
        case inferenceFailed
        case unsupportedFeature
        
        var errorDescription: String? {
            switch self {
            case .modelLoadFailed: return "임베딩 모델을 불러오는데 실패했습니다"
            case .inferenceFailed: return "임베딩 생성에 실패했습니다"
            case .unsupportedFeature: return "지원하지 않는 기능입니다"
            }
        }
    }
    
    public init() {}
    
    /// Generates a text embedding vector from the given text.
    /// Returns a float array of embeddingDimension size.
    func generateEmbedding(for text: String) async throws -> [Float] {
        isGenerating = true
        defer { isGenerating = false }
        
        // Placeholder: use a simple hash-based embedding
        // In production: use a Core ML text embedding model (e.g., Sentence-Tiny)
        guard let model = try? model() else {
            throw EmbeddingError.modelLoadFailed
        }
        
        // Try MLModel approach first
        do {
            let embeddings = try await generateWithMLModel(model, text: text)
            return embeddings
        } catch {
            // Fallback to hash-based placeholder
            return hashEmbedding(text: text, dimension: embeddingDimension)
        }
    }
    
    /// Placeholder model loader — returns nil until a .mlmodel is added.
    private func model() throws -> MLModel? {
        return nil
    }
    
    private func generateWithMLModel(_ model: MLModel, text: String) async throws -> [Float] {
        return hashEmbedding(text: text, dimension: embeddingDimension)
    }
    
    /// Simple hash-based embedding (placeholder for ML model).
    /// Maps text to a deterministic vector using character hash mixing.
    private func hashEmbedding(text: String, dimension: Int) -> [Float] {
        var vector = [Float](repeating: 0.0, count: dimension)
        let encoded = text.data(using: .utf8) ?? Data()
        
        for i in 0..<encoded.count {
            let byte = encoded[i]
            let position = Int(byte) % dimension
            // Hash mixing to spread values
            let value = ((Float(byte) / 255.0) - 0.5) * Float(i + 1) * 0.01
            vector[position] += value
        }
        
        // L2 normalize
        let magnitude = sqrt(vector.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            vector = vector.map { $0 / magnitude }
        }
        
        return vector
    }
}
