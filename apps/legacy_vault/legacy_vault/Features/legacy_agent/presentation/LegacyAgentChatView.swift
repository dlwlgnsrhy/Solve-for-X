import SwiftUI
import CoreData

// MARK: - LegacyAgentChatView

@MainActor

struct LegacyAgentChatView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @StateObject private var llmService = LocalLLMService.shared
    @State private var userInput: String = ""
    @State private var currentPersonality: Personality = .lifeWise
    
    var messages: [CLCChatMessage] {
        let fetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
        fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return (try? databaseManager.mainContext.fetch(fetch)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if messages.isEmpty && !llmService.isGenerating {
                        welcomeMessage
                    } else {
                        MessageListView(messages: messages, currentPersonality: currentPersonality)
                            .environmentObject(databaseManager)
                    }
                    
                    if llmService.isGenerating {
                        typingIndicator
                    }
                    
                    MessageInputBar(
                        text: $userInput,
                        personality: currentPersonality,
                        onSend: sendMessage
                    )
                }
            }
            .navigationTitle("유산 상담사")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PersonalityPicker(personality: $currentPersonality)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        clearConversation()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                          .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
              .font(.system(size: 44))
              .foregroundStyle(AppColors.accent)
              .padding(.bottom, 4)
            
            Text("당신의 이야기를 들려주세요")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(.white)
            
            Text("\(personalityGreeting), 당신의 유산과 가치에 대해 이야기해 드립니다")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.6))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
            
            let prompts = ["당신의 가장 중요한 추억은?", "자녀에게 전하고 싶은 이야기는?", "인생에서 가장 배운 교훈은?"]
            VStack(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        userInput = prompt
                        sendMessage()
                    } label: {
                        Text(prompt)
                          .font(.system(size: 13))
                          .foregroundStyle(AppColors.neonCyan)
                          .padding(.horizontal, 16)
                          .padding(.vertical, 10)
                          .background(AppColors.neonCyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
                          .overlay(
                              RoundedRectangle(cornerRadius: 20)
                                .stroke(AppColors.neonCyan.opacity(0.2), lineWidth: 1)
                          )
                    }
                }
            }
            Spacer()
        }
    }
    
    private var personalityGreeting: String {
        switch currentPersonality {
        case .lifeWise: return "인생 가이드"
        case .familyGuide: return "가족의 길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치 멘토"
        }
    }
    
    private var typingIndicator: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                  .font(.system(size: 10))
                  .foregroundStyle(AppColors.accent)
                  .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: false), value: llmService.isGenerating)
                
                Capsule()
                  .fill(AppColors.accent.opacity(0.3))
                  .frame(width: 6, height: 6)
                  .overlay(
                      Capsule()
                        .fill(AppColors.accent)
                        .frame(width: 4, height: 4)
                        .offset(y: 1)
                  )
                Text("상담사")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.white.opacity(0.05), in: Capsule())
            .padding(.trailing, 16)
        }
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = CLCChatMessage(context: databaseManager.mainContext)
        userMessage.id = UUID().uuidString
        userMessage.role = "user"
        userMessage.content = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        userMessage.timestamp = Date()
        
        let history = (try? databaseManager.mainContext.fetch(CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>)) ?? []
        userInput = ""
        
        Task {
            do {
                let _ = try await llmService.generateResponse(
                    userMessage: userMessage.content,
                    personality: currentPersonality,
                    history: history
                )
                
                let aiMessage = CLCChatMessage(context: databaseManager.mainContext)
                aiMessage.id = UUID().uuidString
                aiMessage.role = "assistant"
                aiMessage.content = llmService.partialResponse
                aiMessage.timestamp = Date()
                
                try databaseManager.saveContext()
            } catch {
                print("LLM generation failed: \(error)")
            }
        }
    }
    
    private func clearConversation() {
        // Fetch and delete all chat messages
        let fetch: NSFetchRequest<NSFetchRequestResult> = CLCChatMessage.fetchRequest()
        if let results = try? databaseManager.mainContext.fetch(fetch) as? [NSManagedObject] {
            for object in results {
                databaseManager.mainContext.delete(object)
            }
            try? databaseManager.saveContext()
        }
    }
}

// MARK: - Message List View

                private struct MessageListView: View {
    let messages: [CLCChatMessage]
    let currentPersonality: Personality
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages, id: \.objectID) { message in
                        ChatBubble(
                            message: message,
                            isUser: message.role == "user",
                            personality: currentPersonality
                        )
                        .id(message.id)
                    }
                    Color.clear.frame(height: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastId = messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Chat Bubble

                private struct ChatBubble: View {
    let message: CLCChatMessage
    let isUser: Bool
    let personality: Personality
    
    private var bubbleColor: Color {
        isUser ? AppColors.accent : AppColors.surfaceVariant
    }
    
    private var bubbleText: Color {
        isUser ? .white : .white
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.content)
                      .font(.system(size: 14))
                      .foregroundStyle(bubbleText)
                      .padding(.horizontal, 14)
                      .padding(.vertical, 10)
                      .background(bubbleColor.opacity(0.2), in: BubbleShape(cornerRadius: 16, isUser: true))
                    Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                      .font(.system(size: 10))
                      .foregroundStyle(.white.opacity(0.4))
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    // AI label
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                          .font(.system(size: 10))
                          .foregroundStyle(personalityColor)
                        Text(personalityLabel)
                          .font(.system(size: 11, weight: .medium))
                          .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Text(message.content)
                      .font(.system(size: 14))
                      .foregroundStyle(bubbleText)
                      .padding(.horizontal, 14)
                      .padding(.vertical, 10)
                      .background(.white.opacity(0.06), in: BubbleShape(cornerRadius: 16, isUser: false))
                    
                    Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                      .font(.system(size: 10))
                      .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.leading, 28)
                
                Spacer()
                
                // AI avatar
                ZStack {
                    Circle()
                      .fill(personalityColor.opacity(0.15))
                      .frame(width: 28, height: 28)
                    Image(systemName: "sparkle")
                      .font(.system(size: 12))
                      .foregroundStyle(personalityColor)
                }
                .offset(x: -8)
            }
        }
    }
    
    private var personalityColor: Color {
        switch personality {
        case .lifeWise: return AppColors.accent
        case .familyGuide: return AppColors.neonPink
        case .storyTeller: return AppColors.neonCyan
        case .valuesMentor: return .yellow
        }
    }
    
    private var personalityLabel: String {
        switch personality {
        case .lifeWise: return "인생 가이드"
        case .familyGuide: return "가족의 길잡이"
        case .storyTeller: return "이야기꾼"
        case .valuesMentor: return "가치 멘토"
        }
    }
}

// MARK: - Bubble Shape

private struct BubbleShape: InsettableShape {
    var cornerRadius: CGFloat
    var isUser: Bool
    
        func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.cornerRadius += amount
        return shape
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topRight = CGPoint(x: rect.maxX - cornerRadius, y: cornerRadius)
        let bottomRight = CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius)
        let bottomLeft = CGPoint(x: cornerRadius, y: rect.maxY - cornerRadius)
        let topLeft = CGPoint(x: cornerRadius, y: cornerRadius)
        
        path.move(to: isUser
            ? CGPoint(x: topLeft.x, y: topLeft.y + cornerRadius)
            : CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius)
        )
        
        // Top edge
        path.addLine(to: isUser
            ? CGPoint(x: rect.maxX - cornerRadius, y: topLeft.y)
            : CGPoint(x: rect.maxX, y: topLeft.y)
        )
        path.addArc(center: isUser ? topRight : CGPoint(x: rect.maxX - cornerRadius, y: topLeft.y),
                     radius: cornerRadius,
                     startAngle: Angle(degrees: isUser ? -90 : 0),
                     endAngle: Angle(degrees: isUser ? 0 : 90),
                     clockwise: false)
        
        // Bottom edge — with tail
        if isUser {
            path.addArc(center: CGPoint(x: bottomRight.x, y: bottomRight.y),
                         radius: cornerRadius,
                         startAngle: Angle(degrees: 0),
                         endAngle: Angle(degrees: 90),
                         clockwise: false)
            path.addLine(to: CGPoint(x: bottomRight.x - cornerRadius, y: rect.maxY))
            path.addLine(to: CGPoint(x: bottomRight.x, y: rect.maxY))
            path.addLine(to: CGPoint(x: bottomRight.x - cornerRadius, y: rect.maxY))
        } else {
            path.addArc(center: bottomLeft,
                         radius: cornerRadius,
                         startAngle: Angle(degrees: -90),
                         endAngle: Angle(degrees: -180),
                         clockwise: false)
            path.addLine(to: CGPoint(x: topLeft.x, y: rect.maxY))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Message Input Bar

                private struct MessageInputBar: View {
        @Binding var text: String
        let personality: Personality
        let onSend: () -> Void
        
        var body: some View {
            HStack(spacing: 10) {
                // Personality indicator
                ZStack {
                    Circle()
                      .fill(personalityColor.opacity(0.2))
                      .frame(width: 36, height: 36)
                    Image(systemName: "sparkle")
                      .font(.system(size: 14))
                      .foregroundStyle(personalityColor)
                }
                .padding(.trailing, 4)
                
                TextField("메시지를 입력하세요...", text: $text, axis: .vertical)
                  .padding(12)
                  .textFieldStyle(VaultTextFieldStyle())
                  .lineLimit(1...4)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                      .font(.system(size: 30))
                      .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          ? .white.opacity(0.3)
                          : AppColors.accent)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.surface)
        }
        
        private var personalityColor: Color {
            switch personality {
            case .lifeWise: return AppColors.accent
            case .familyGuide: return AppColors.neonPink
            case .storyTeller: return AppColors.neonCyan
            case .valuesMentor: return .yellow
            }
        }
    }
    
    // MARK: - Personality Picker
    
                        private struct PersonalityPicker: View {
        @Binding var personality: Personality
        
        var body: some View {
            Menu {
                Picker("Personality", selection: $personality) {
                    ForEach(Personality.allCases, id: \.self) { p in
                        Text(personalityIcon(p) + " " + personalityLabel(p))
                          .tag(p)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                      .foregroundStyle(personalityColor)
                    Text(personalityLabel(personality))
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.8))
                    Image(systemName: "chevron.down")
                      .font(.system(size: 10))
                      .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        
        private var personalityColor: Color {
            switch personality {
            case .lifeWise: return AppColors.accent
            case .familyGuide: return AppColors.neonPink
            case .storyTeller: return AppColors.neonCyan
            case .valuesMentor: return .yellow
            }
        }
        
        private func personalityLabel(_ p: Personality) -> String {
            switch p {
            case .lifeWise: return "인생 가이드"
            case .familyGuide: return "가족의 길잡이"
            case .storyTeller: return "이야기꾼"
            case .valuesMentor: return "가치 멘토"
            }
        }
        
        private func personalityIcon(_ p: Personality) -> String {
            switch p {
            case .lifeWise: return "🌿"
            case .familyGuide: return "👨‍👩‍👧"
            case .storyTeller: return "📖"
            case .valuesMentor: return "💎"
            }
        }
    }
    
    // MARK: - Personality Extension
    
    extension Personality: CaseIterable {
        static var allCases: [Personality] = [.lifeWise, .familyGuide, .storyTeller, .valuesMentor]
    }
    
    // MARK: - Preview
    
// Preview disabled for compilation compatibility
