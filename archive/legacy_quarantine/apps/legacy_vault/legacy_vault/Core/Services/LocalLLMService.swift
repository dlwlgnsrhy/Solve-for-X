import Foundation
import SwiftUI

@MainActor
final class LocalLLMService: ObservableObject {
    static let shared = LocalLLMService()
    
    @Published var isGenerating: Bool = false
    @Published var partialResponse: String = ""
    
    private let knownPersonalities: [Personality] = [
        .lifeWise,
        .familyGuide,
        .storyTeller,
        .valuesMentor
    ]
    
    public init() {}
    
    /// Generates a simulated on-device LLM response based on the user's message
    /// and the conversation context.
    /// The response is patterned after a warm, wise personal assistant.
    func generateResponse(
        userMessage: String,
        personality: Personality = .lifeWise,
        history: [CLCChatMessage],
        soulMiningContext: [String] = []
    ) async throws -> String {
        isGenerating = true
        defer { isGenerating = false }
        
        // Simulate streaming-like latency
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let context = buildContext(userMessage: userMessage, history: history, soulMiningContext: soulMiningContext)
        let response = simulateResponse(from: context, personality: personality)
        
        partialResponse = response
        return response
    }
    
    /// Summarizes the given transcript with AI enrichment.
    func summarizeTranscript(_ transcript: String) async throws -> (summary: String, enrichment: String) {
        isGenerating = true
        defer { isGenerating = false }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let sentences = transcript.split(separator: ".")
        let firstFew = sentences.prefix(min(5, sentences.count)).joined(separator: ".")
        
        let summary = generateSummary(from: firstFew)
        let enrichment = generateEnrichment(from: transcript)
        
        partialResponse = summary
        return (summary, enrichment)
    }
    
    /// Extracts keywords and sentiment from text.
    func extractInsights(from text: String) async throws -> (keywords: [String], sentiment: Int) {
        isGenerating = true
        defer { isGenerating = false }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let keywords = extractKeywords(from: text)
        let sentiment = calculateSentiment(from: text)
        
        return (keywords, sentiment)
    }
    
    private func buildContext(userMessage: String, history: [CLCChatMessage], soulMiningContext: [String]) -> String {
        var context = "사용자가 묻습니다: \(userMessage)\n\n"
        
        if !soulMiningContext.isEmpty {
            context += "관련 영혼 채굴 기록:\n"
            for ctx in soulMiningContext {
                context += "- \(ctx)\n"
            }
            context += "\n"
        }
        
        let recentHistory = Array(history.prefix(10))
        if !recentHistory.isEmpty {
            context += "대화 이력:\n"
            for msg in recentHistory {
                let roleText = msg.role == "user" ? "나" : "상담사"
                context += "\(roleText): \(msg.content)\n"
            }
        }
        
        return context
    }
    
    private func simulateResponse(from context: String, personality: Personality) -> String {
        let responses = [
            """
            \(personality.greeting). 당신의 이야기를 들어보니, 정말 깊은 성찰이 담긴 순간이네요. 
            
            특히 중요해 보이는 몇 가지가 있어요:
            • 당신의 감정과 가치를 솔직하게 표현했어요
            • 주변 사람들과의 관계에서 중요한 교훈이 보입니다
            • 앞으로의 삶에 대한 통찰이 담겨 있습니다
            
            이 기록은 정말 소중합니다. 계속해 보세요.
            """,
            """
            좋은 질문이에요. 제가 지금까지 들었던 당신의 이야기에서,
            가장 인상 깊었던 점은 당신의 진정성이네요.
            
            삶에서 진짜 중요한 것은 기술이나 재력보다는
            이러한 내면의 가치들인 것 같아요.
            이 내용을 바탕으로 더 깊이 파고들어 볼까요?
            """,
            """
            알겠습니다. 당신의 이야기를 정리해 드릴게요.
            
            지금까지의 대화에서 드러난 핵심은 당신의 삶에서
            "진정한 연결"과 "의미 있는 가치"를 추구하는 모습이에요.
            
            이는 매우 중요한 통찰입니다.
            이 방향으로 더 이야기해 볼까요?
            """
        ]
        
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateSummary(from text: String) -> String {
        let lines = text.split(separator: ".")
        let keyLines = lines.prefix(min(3, lines.count))
        
        guard let first = keyLines.first, let last = keyLines.last else {
            return text.prefix(200) + "..."
        }
        
        return "요약: \(String(first)). 이 이야기를 통해 \(String(last))."
    }
    
    private func generateEnrichment(from text: String) -> String {
        let hasFamily = text.contains("가족") || text.contains("아빠") || text.contains("엄마") || text.contains("딸") || text.contains("아들")
        let hasCareer = text.contains("일") || text.contains("직장") || text.contains("사업") || text.contains("취미")
        let hasEmotion = text.contains("기쁘") || text.contains("슬프") || text.contains("고마") || text.contains("두려")
        
        var insights: [String] = []
        if hasFamily { insights.append("가족에 대한 깊은 애정") }
        if hasCareer { insights.append("일에 대한 헌신과 열정") }
        if hasEmotion { insights.append("감정의 깊이는 강렬한 인간성") }
        
        insights.append("자녀에게 전달할 소중한 가치")
        
        return "💡 통찰: \(insights.joined(separator: " • "))\n\n이 기록은 자녀와 손자에게 큰 위로가 될 것입니다."
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let wordList = ["가족", "사랑", "행복", "노력", "용기", "희망", "꿈", "우정", "성장", "감사",
                       "가치", "철학", "삶", "인생", "전통", "유산", "유산", "기억", "훈말", "지혜"]
        return wordList.filter { text.contains($0) }
    }
    
    private func calculateSentiment(from text: String) -> Int {
        let positive = ["기쁘", "행복", "고마", "사랑", "희망", "감사", "자부", "열정", "꿈", "자랑"]
        let negative = ["슬프", "아쉬", "후회", "두려", "힘들", "외로", "노여", "걱정", "실패"]
        
        var score = 0
        for word in positive where text.contains(word) { score += 2 }
        for word in negative where text.contains(word) { score -= 2 }
        
        return max(-3, min(3, score))
    }
}

// MARK: - Personality

enum Personality: String, Codable {
    case lifeWise = "indogirim"
    case familyGuide = "gyeyo"
    case storyTeller = "yeoksa"
    case valuesMentor = "gachi"
    
    var greeting: String {
        switch self {
        case .lifeWise: return "안녕하세요, 인생 가이드입니다"
        case .familyGuide: return "안녕하세요, 가족의 길잡이입니다"
        case .storyTeller: return "안녕하세요, 이야기꾼입니다"
        case .valuesMentor: return "안녕하세요, 가치 멘토입니다"
        }
    }
}
