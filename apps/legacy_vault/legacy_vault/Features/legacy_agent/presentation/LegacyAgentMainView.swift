import SwiftUI
import CoreData

// MARK: - LegacyAgentMainView

@MainActor

struct LegacyAgentMainView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @State private var selectedPersonality: Personality = .lifeWise
    
    var recentConversations: [CLCChatMessage] {
        let fetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
        fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetch.fetchLimit = 10
        return (try? databaseManager.mainContext.fetch(fetch)) ?? []
    }
    
    var conversationCount: Int {
        let fetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
        return (try? databaseManager.mainContext.fetch(fetch))?.count ?? 0
    }
    
    var firstConversationDate: Date? {
        let fetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
        fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        fetch.fetchLimit = 1
        return (try? databaseManager.mainContext.fetch(fetch))?.first?.timestamp
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        heroSection
                        quickStartSection
                        recentConversationsSection
                        personalitySection
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("유산 상담사")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                  .fill(AppColors.accent.opacity(0.08))
                  .frame(width: 120, height: 120)
                Circle()
                  .fill(AppColors.accent.opacity(0.04))
                  .frame(width: 90, height: 90)
                Text(personalityCurrentEmoji)
                  .font(.system(size: 44))
            }
            
            VStack(spacing: 6) {
                Text("당신의 이야기를 이어갑니다")
                  .font(.system(size: 20, weight: .bold))
                  .foregroundStyle(.white)
                Text("당신의 유산과 가치를 AI 상담사가 함께해요")
                  .font(.system(size: 14))
                  .foregroundStyle(.white.opacity(0.6))
                  .multilineTextAlignment(.center)
            }
            
            if let date = firstConversationDate {
                Text("상담 시작: \(date, format: .dateTime.year().month().day())")
                  .font(.system(size: 12))
                  .foregroundStyle(AppColors.accent)
            }
        }
        .padding(24)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(AppColors.accent.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var personalityCurrentEmoji: String {
        switch selectedPersonality {
        case .lifeWise: return "🌿"
        case .familyGuide: return "👨‍👩‍👧"
        case .storyTeller: return "📖"
        case .valuesMentor: return "💎"
        }
    }
    
    // MARK: - Quick Start Section
    
    private var quickStartSection: some View {
        Button {
            startNewConversation()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                      .fill(AppColors.neonCyan.opacity(0.12))
                      .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                      .font(.system(size: 22))
                      .foregroundStyle(AppColors.neonCyan)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("유산 이야기 시작하기")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(.white)
                    Text("\(selectedPersonality.label) 상담사와 이야기하세요")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.55))
                }
                
                Spacer()
                
                Circle()
                  .fill(AppColors.neonCyan)
                  .frame(width: 28, height: 28)
                  .overlay {
                      Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                  }
            }
            .padding(16)
            .background(AppColors.neonCyan.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(AppColors.neonCyan.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Recent Conversations Section
    
    private var recentConversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 대화")
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(.white)
                Spacer()
                Text("\(conversationCount)개")
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.5))
            }
            
            if recentConversations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                      .font(.system(size: 24))
                      .foregroundStyle(.white.opacity(0.2))
                    Text("아직 대화 내역이 없어요")
                      .font(.system(size: 14))
                      .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                NavigationLink(destination: LegacyAgentChatView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                              .fill(personalityCurrentColor.opacity(0.12))
                              .frame(width: 40, height: 40)
                            Image(systemName: "sparkle")
                              .font(.system(size: 16))
                              .foregroundStyle(personalityCurrentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("유산 상담사")
                              .font(.system(size: 14, weight: .semibold))
                              .foregroundStyle(.white)
                            let lastMsg = recentConversations.prefix(5).last
                            Text(lastMsg?.content.prefix(50) ?? "대화 시작")
                              .font(.system(size: 12))
                              .foregroundStyle(.white.opacity(0.5))
                              .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(lastMessageTime)
                              .font(.system(size: 11))
                              .foregroundStyle(.white.opacity(0.4))
                            Image(systemName: "chevron.right")
                              .font(.system(size: 12))
                              .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(12)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var personalityCurrentColor: Color {
        switch selectedPersonality {
        case .lifeWise: return AppColors.accent
        case .familyGuide: return AppColors.neonPink
        case .storyTeller: return AppColors.neonCyan
        case .valuesMentor: return .yellow
        }
    }
    
    private var lastMessageTime: String {
        guard let lastMsg = recentConversations.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: lastMsg.timestamp)
    }
    
    // MARK: - Personality Selection
    
    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("상담사 선택")
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(.white)
                Spacer()
                Text("탭하여 변경")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.4))
            }
            
            HStack(spacing: 10) {
                ForEach(Personality.allCases.indices, id: \.self) { index in
                    let p = Personality.allCases[index]
                    PersonalityMiniCard(
                        personality: p,
                        isSelected: p == selectedPersonality,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPersonality = p
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func startNewConversation() {
    }
}

// MARK: - Personality Mini Card

                private struct PersonalityMiniCard: View {
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                  .font(.system(size: 22))
                
                Text(personality.shortLabel)
                  .font(.system(size: 11, weight: .medium))
                  .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                  .lineLimit(1)
                
                if isSelected {
                    Rectangle()
                      .fill(color)
                      .frame(height: 2)
                      .clipShape(RoundedRectangle(cornerRadius: 1))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                color.opacity(isSelected ? 0.1 : 0.04),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(color.opacity(isSelected ? 0.5 : 0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Personality Short Label Extension

extension Personality {
    var shortLabel: String {
        switch self {
        case .lifeWise: return "인생가이드"
        case .familyGuide: return "가족길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치멘토"
        }
    }
    
    var label: String {
        switch self {
        case .lifeWise: return "인생 가이드"
        case .familyGuide: return "가족의 길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치 멘토"
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
