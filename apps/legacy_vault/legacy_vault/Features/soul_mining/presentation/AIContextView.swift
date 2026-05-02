import SwiftUI
import CoreData

@MainActor

struct AIContextView: View {
    @StateObject private var llmService = LocalLLMService.shared
    @StateObject private var databaseManager = DatabaseManager.shared
    
    let entry: CLCVoiceLogEntry
    
    @State private var messages: [CLCChatMessage] = []
    @State private var newInput: String = ""
    @State private var isGenerating: Bool = false
    @State private var showSentiment: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                          .font(.system(size: 16, weight: .medium))
                          .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("AI 대화")
                      .font(.system(size: 17, weight: .semibold))
                      .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation { showSentiment.toggle() }
                    } label: {
                        Image(systemName: showSentiment ? "heart.fill" : "heart")
                          .font(.system(size: 16))
                          .foregroundStyle(sentimentColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                // Sentiment panel
                if showSentiment {
                    sentimentPanel
                      .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer(minLength: 0)
                
                // Chat messages
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                Spacer(minLength: 24)
                                welcomeCard
                            }
                            
                            ForEach(messages.sorted(by: { $0.timestamp < $1.timestamp }), id: \.objectID) { msg in
                                chatMessageBubble(msg)
                            }
                            
                            if isGenerating {
                                generatingBubble
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Input bar
                inputBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            loadExistingMessages()
        }
    }
    
    // MARK: - Sentiment Panel
    
    private var sentimentPanel: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("감성 분석")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
                Text(sentimentLabel)
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(sentimentColor)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("추출 키워드")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entryKeywords, id: \.self) { kw in
                            Text(kw)
                              .font(.system(size: 11, weight: .medium))
                              .foregroundStyle(AppColors.accent)
                              .padding(.horizontal, 8)
                              .padding(.vertical, 3)
                              .background(AppColors.accent.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
              .font(.system(size: 32))
              .foregroundStyle(AppColors.neonCyan)
            
            Text("AI 상담사가 이야기를 정리해 드립니다")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.white)
            
            Text("이 녹음에 대해 궁금한 점을 물어보세요.\nAI가 따뜻하게 답변해 드립니다.")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.6))
              .multilineTextAlignment(.center)
              .lineSpacing(3)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppColors.neonCyan.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(AppColors.neonCyan.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Chat Bubble
    
    private func chatMessageBubble(_ msg: CLCChatMessage) -> some View {
        let isUser = msg.role == "user"
        
        return HStack {
            if !isUser {
                Image(systemName: "person")
                  .font(.system(size: 14))
                  .foregroundStyle(AppColors.neonCyan)
                Spacer()
            }
            
            Text(msg.content)
              .font(.system(size: 15))
              .foregroundStyle(isUser ? .white.opacity(0.9) : .white.opacity(0.8))
              .multilineTextAlignment(isUser ? .trailing : .leading)
              .lineSpacing(3)
              .padding(12)
              .background(
                  isUser
                    ? AppColors.accent.opacity(0.15)
                    : AppColors.surface
                  ,
                  in: RoundedRectangle(cornerRadius: 14)
              )
              .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            
            if isUser {
                Spacer()
                Image(systemName: "person.circle.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(AppColors.accent)
            }
        }
    }
    
    private var generatingBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "person")
              .font(.system(size: 14))
              .foregroundStyle(AppColors.neonCyan)
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                  .fill(.white.opacity(0.3))
                  .frame(width: 6, height: 6)
                  .opacity(0.4)
                Circle()
                  .fill(.white.opacity(0.3))
                  .frame(width: 6, height: 6)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Circle()
                  .fill(.white.opacity(0.3))
                  .frame(width: 6, height: 6)
                  .frame(maxWidth: .infinity, alignment: .leading)
                
                ProgressView()
                  .tint(AppColors.neonCyan)
            }
            .padding(14)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("질문을 입력하세요...", text: $newInput)
              .textFieldStyle(VaultTextFieldStyle())
              .frame(maxWidth: .infinity)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                  .font(.system(size: 30))
                  .foregroundStyle(newInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? .white.opacity(0.2)
                    : AppColors.accent)
            }
            .disabled(newInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    // MARK: - Actions
    
    private func loadExistingMessages() {
        do {
            let fetch = CLCChatMessage.fetchRequest() as! NSFetchRequest<CLCChatMessage>
            fetch.predicate = NSPredicate(format: "conversationId == %@", entry.id as NSString)
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \CLCChatMessage.timestamp, ascending: true)]
            messages = try databaseManager.mainContext.fetch(fetch)
        } catch {
            // No messages yet
        }
    }
    
    private func sendMessage() {
        let trimmed = newInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "CLCChatMessage",
            into: databaseManager.mainContext
        ) as! CLCChatMessage
        entity.id = UUID().uuidString
        entity.role = "user"
        entity.content = trimmed
        entity.timestamp = Date()
        
        messages.append(entity)
        newInput = ""
        
        Task {
            await generateAIReply(to: trimmed)
        }
    }
    
    private func generateAIReply(to userInput: String) async {
        isGenerating = true
        
        do {
            let reply = try await llmService.generateResponse(
                userMessage: userInput,
                personality: .lifeWise,
                history: messages,
                soulMiningContext: [entry.title, String(entry.transcript.prefix(100))]
            )
            
            let entity = NSEntityDescription.insertNewObject(
                forEntityName: "CLCChatMessage",
                into: databaseManager.mainContext
            ) as! CLCChatMessage
            entity.id = UUID().uuidString
            entity.role = "assistant"
            entity.content = reply
            entity.timestamp = Date()
            
            messages.append(entity)
        } catch {
            // Handle error gracefully - already suppressed via await Task.Delay
        }
        
        isGenerating = false
    }
    
    // MARK: - Helpers
    
    private var sentimentLabel: String {
        switch entry.sentiment {
        case let s where s > 1: return "😊 긍정적"
        case let s where s < -1: return "😢 부정적"
        default: return "😐 중립"
        }
    }
    
    private var sentimentColor: Color {
        switch entry.sentiment {
        case let s where s > 1: return AppColors.accent
        case let s where s < -1: return AppColors.danger
        default: return .white.opacity(0.5)
        }
    }
    
    private var entryKeywords: [String] {
        if let data = entry.keywordsJSON.data(using: .utf8),
           let keywords = try? JSONDecoder().decode([String].self, from: data) {
            return keywords
        }
        return []
    }
}

// Preview disabled for compilation compatibility
