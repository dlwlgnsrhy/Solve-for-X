import SwiftUI
import CoreData

// MARK: - LegacyAgentPersonaView

@MainActor

struct LegacyAgentPersonaView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    
    @AppStorage("personaConfiguration") private var currentPersonality: String = Personality.lifeWise.rawValue
    @AppStorage("responseStyle") private var responseStyle: String = "conversational"
    
    var personality: Personality {
        Personality(rawValue: currentPersonality) ?? .lifeWise
    }
    
    var selectedPersonaIndex: Int {
        Personality.allCases.firstIndex { $0.rawValue == currentPersonality } ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        currentPersonaDisplay
                        personalitySelectionGrid
                        responseStyleSection
                        testChatPreview
                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("성격 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
                }
            }
        }
    }
    
    // MARK: - Current Persona Display
    
    private var currentPersonaDisplay: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                  .fill(personalityColor.opacity(0.12))
                  .frame(width: 80, height: 80)
                Text(personaEmoji)
                  .font(.system(size: 36))
            }
            
            VStack(spacing: 4) {
                Text(personaName)
                  .font(.system(size: 20, weight: .bold))
                  .foregroundStyle(personalityColor)
                Text(personaDescription)
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.6))
                  .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var personalityColor: Color {
        switch personality {
        case .lifeWise: return AppColors.accent
        case .familyGuide: return AppColors.neonPink
        case .storyTeller: return AppColors.neonCyan
        case .valuesMentor: return .yellow
        }
    }
    
    private var personaEmoji: String {
        switch personality {
        case .lifeWise: return "🌿"
        case .familyGuide: return "👨‍👩‍👧"
        case .storyTeller: return "📖"
        case .valuesMentor: return "💎"
        }
    }
    
    private var personaName: String {
        switch personality {
        case .lifeWise: return "인생 가이드"
        case .familyGuide: return "가족의 길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치 멘토"
        }
    }
    
    private var personaDescription: String {
        switch personality {
        case .lifeWise:
            return "인생의 지혜를 전하는 현명한 조언자"
        case .familyGuide:
            return "가족을 위해 길을 찾아주는 안내자"
        case .storyTeller:
            return "인생 이야기를 아름답게 풀어내는 이야기꾼"
        case .valuesMentor:
            return "당신의 가치를 일깨우는 멘토"
        }
    }
    
    // MARK: - Personality Selection Grid
    
    private var personalitySelectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("상담사 성격 선택")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Personality.allCases.indices, id: \.self) { index in
                    PersonalitySelectionCard(
                        personality: Personality.allCases[index],
                        isSelected: index == selectedPersonaIndex,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPersonality = Personality.allCases[index].rawValue
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Response Style Section
    
    private var responseStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("응답 스타일")
            
            ResponseStyleOption(
                title: "편안한 대화",
                subtitle: "자연스럽고 친절하게 답변해요",
                icon: "chat.bubble.fill",
                isSelected: responseStyle == "conversational",
                value: "conversational"
            )
            
            ResponseStyleOption(
                title: "깊은 성찰",
                subtitle: "깊이 있는 질문과 통찰을 제공해요",
                icon: "lightbulb.fill",
                isSelected: responseStyle == "reflective",
                value: "reflective"
            )
            
            ResponseStyleOption(
                title: "스토리텔링",
                subtitle: "이야기 형식으로 전달해요",
                icon: "book.fill",
                isSelected: responseStyle == "narrative",
                value: "narrative"
            )
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Test Chat Preview
    
    private var testChatPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("미리보기 대화")
            
            ScrollView {
                VStack(spacing: 8) {
                    // User message
                    HStack {
                        Spacer()
                        Text("당신의 삶의 철학은 무엇인가요?")
                          .font(.system(size: 13))
                          .foregroundStyle(.white)
                          .padding(.horizontal, 12)
                          .padding(.vertical, 8)
                          .background(AppColors.accent.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // AI response
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkle")
                                  .font(.system(size: 9))
                                  .foregroundStyle(personalityColor)
                                Text(personaName)
                                  .font(.system(size: 10, weight: .medium))
                                  .foregroundStyle(.white.opacity(0.5))
                            }
                            Text(testPreviewResponse)
                              .font(.system(size: 13))
                              .foregroundStyle(.white.opacity(0.85))
                              .padding(.vertical, 4)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                              .fill(personalityColor.opacity(0.12))
                              .frame(width: 24, height: 24)
                            Image(systemName: "sparkle")
                              .font(.system(size: 10))
                              .foregroundStyle(personalityColor)
                        }
                        .offset(x: -6)
                    }
                }
                .padding(12)
                .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var testPreviewResponse: String {
        switch personality {
        case .lifeWise:
            return "삶의 철학은 단순함이 최고라는 믿음이네. 복잡한 것을 단순하게, 단순한 것을 아름답게 — 이것이 나의 길이오."
        case .familyGuide:
            return "제 철학은 가족이 모든 것이라는 거예요. 함께 웃고 함께 울며, 그 순간들이 가장 소중한 유산이 되거든요."
        case .storyTeller:
            return "인생은 하나의 큰 이야기라고 믿어요. 각 장막이 의미를 가지고, 마지막에 돌아가면 아름다운 전체가 되는 거죠."
        case .valuesMentor:
            return "내 안의 진정한 가치를 발견하고 그 방향으로 살아가는 것 — 그것이 바로 가장 중요한 삶의 철학이에요."
        }
    }
    
    // MARK: - Actions
    
    private func saveConfiguration() {
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.white)
    }
}

// MARK: - Personality Card

                private struct PersonalitySelectionCard: View {
    let personality: Personality
    let isSelected: Bool
    let action: () -> Void
    
    private var color: Color {
        switch personality {
        case .lifeWise: return AppColors.accent
        case .familyGuide: return AppColors.neonPink
        case .storyTeller: return AppColors.neonCyan
        case .valuesMentor: return .yellow
        }
    }
    
    private var emoji: String {
        switch personality {
        case .lifeWise: return "🌿"
        case .familyGuide: return "👨‍👩‍👧"
        case .storyTeller: return "📖"
        case .valuesMentor: return "💎"
        }
    }
    
    private var name: String {
        switch personality {
        case .lifeWise: return "인생 가이드"
        case .familyGuide: return "가족의 길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치 멘토"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji)
                  .font(.system(size: 28))
                
                Text(name)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                  .lineLimit(1)
                
                Text(personality.description)
                  .font(.system(size: 11))
                  .foregroundStyle(.white.opacity(0.6))
                  .multilineTextAlignment(.center)
                  .lineLimit(2)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                      .font(.system(size: 20))
                      .foregroundStyle(color)
                      .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                Color.clear,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                  .stroke(
                    isSelected ? color.opacity(0.6) : .white.opacity(0.1),
                    lineWidth: isSelected ? 2 : 1
                  )
            )
            .background(
                color.opacity(isSelected ? 0.08 : 0.03),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
    }
}

// MARK: - Response Style Option

                private struct ResponseStyleOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let value: String
    
    @AppStorage("responseStyle") private var responseStyle: String = "conversational"
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                responseStyle = value
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                      .fill(isSelected ? AppColors.accent.opacity(0.2) : .white.opacity(0.06))
                      .frame(width: 42, height: 42)
                    Image(systemName: icon)
                      .font(.system(size: 16))
                      .foregroundStyle(isSelected ? AppColors.accent : .white.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                      .font(.system(size: 14, weight: .semibold))
                      .foregroundStyle(.white)
                    Text(subtitle)
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.55))
                }
                
                Spacer()
                
                Circle()
                  .fill(isSelected ? AppColors.accent : .clear)
                  .frame(width: 20, height: 20)
                  .overlay {
                      if isSelected {
                          Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                      }
                  }
                  .overlay(
                      Circle()
                        .stroke(AppColors.accent.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                  )
            }
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Personality Description Extension

extension Personality {
    var description: String {
        switch self {
        case .lifeWise: return "지혜와 통찰"
        case .familyGuide: return "사랑과 연결"
        case .storyTeller: return "이야기와 기억"
        case .valuesMentor: return "가치와 원칙"
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
