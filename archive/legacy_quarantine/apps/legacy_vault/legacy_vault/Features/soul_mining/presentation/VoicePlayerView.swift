import SwiftUI
import CoreData

@MainActor

struct VoicePlayerView: View {
    @StateObject private var llmService = LocalLLMService.shared
    @StateObject private var databaseManager = DatabaseManager.shared
    
    let entry: CLCVoiceLogEntry
    
    @State private var isPlaying: Bool = false
    @State private var progress: Double = 0.0
    @State private var progressTimer: Timer?
    @State private var showEnrichPanel: Bool = false
    @State private var isEnriching: Bool = false
    @State private var enrichmentText: String = ""
    @State private var summaryText: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var editingTranscript: Bool = false
    @State private var editedText: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private var durationSeconds: Double {
        entry.durationMs > 0 ? Double(entry.durationMs) / 1000.0 : 60.0
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Entry Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                              .font(.system(size: 18, weight: .semibold))
                              .foregroundStyle(.white)
                            
                            HStack(spacing: 8) {
                                Text(entryDateText)
                                  .font(.system(size: 12))
                                  .foregroundStyle(.white.opacity(0.5))
                                
                                Text("•")
                                  .foregroundStyle(.white.opacity(0.3))
                                
                                Text(durationText)
                                  .font(.system(size: 12))
                                  .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        
                        Spacer()
                        
                        Menu {
                            Button("편집하기") { editingTranscript = true }
                            Button("삭제하기", role: .destructive) { showDeleteConfirm = true }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                              .font(.system(size: 20))
                              .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // MARK: - Playback Controls
                    VStack(spacing: 16) {
                        HStack {
                            Text(formatTime(progress * durationSeconds))
                              .font(.system(size: 12, design: .monospaced))
                              .foregroundStyle(.white.opacity(0.6))
                            
                            Slider(value: $progress)
                              .tint(AppColors.accent)
                            
                            Text(formatTime(durationSeconds))
                              .font(.system(size: 12, design: .monospaced))
                              .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 24) {
                            // Previous button (visual only)
                            Button {
                                withAnimation { progress = 0 }
                            } label: {
                                Image(systemName: "backward.fill")
                                  .font(.system(size: 18))
                                  .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            // Play / Pause
                            Button {
                                if isPlaying {
                                    pausePlayback()
                                } else {
                                    startPlayback()
                                }
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                  .font(.system(size: 32))
                                  .foregroundStyle(AppColors.accent)
                            }
                            
                            // Next button (visual only)
                            Button {
                                withAnimation { progress = 1.0 }
                            } label: {
                                Image(systemName: "forward.fill")
                                  .font(.system(size: 18))
                                  .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    // MARK: - Sentiment
                    sentimentBar
                    
                    // MARK: - Transcript
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("본문")
                              .font(.system(size: 14, weight: .semibold))
                              .foregroundStyle(.white)
                            
                            Spacer()
                            
                            TextButton(isEditing: $editingTranscript) {
                                editingTranscript = true
                            }
                        }
                        
                        ScrollView {
                            Text(editingTranscript ? editedText : entry.transcript)
                              .font(.system(size: 15))
                              .foregroundStyle(.white.opacity(0.85))
                              .multilineTextAlignment(.leading)
                              .lineSpacing(4)
                              .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: .infinity)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                              .stroke(.white.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // MARK: - Keywords
                    if !entryKeywords.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "tag")
                                  .font(.system(size: 13))
                                  .foregroundStyle(AppColors.accent)
                                Text("키워드")
                                  .font(.system(size: 13, weight: .medium))
                                  .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(entryKeywords, id: \.self) { keyword in
                                        Text(keyword)
                                          .font(.system(size: 12, weight: .medium))
                                          .foregroundStyle(AppColors.accent)
                                          .padding(.horizontal, 10)
                                          .padding(.vertical, 5)
                                          .background(AppColors.accent.opacity(0.1), in: Capsule())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // MARK: - AI Enrich Action
                    Button {
                        if !showEnrichPanel {
                            Task { await generateEnrichment() }
                        }
                        showEnrichPanel.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "wand.and.stars")
                              .font(.system(size: 16))
                            Text(isEnriching ? "AI 보강 생성 중..." : "AI로 녹음 보강하기")
                              .font(.system(size: 15, weight: .semibold))
                            
                            Spacer()
                            
                            if showEnrichPanel && enrichmentText.isEmpty {
                                ProgressView()
                                  .tint(.white)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                              .stroke(AppColors.accent.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: - Enrichment Result
                    if showEnrichPanel && !enrichmentText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                  .font(.system(size: 13))
                                  .foregroundStyle(AppColors.neonCyan)
                                Text("AI 보강 결과")
                                  .font(.system(size: 13, weight: .medium))
                                  .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            VStack(spacing: 12) {
                                if !summaryText.isEmpty {
                                    Text("📋 \(summaryText)")
                                      .font(.system(size: 14))
                                      .foregroundStyle(.white.opacity(0.8))
                                      .padding(12)
                                      .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                }
                                Text(enrichmentText)
                                  .font(.system(size: 14))
                                  .foregroundStyle(.white.opacity(0.85))
                                  .lineSpacing(3)
                                  .padding(12)
                                  .background(AppColors.neonCyan.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $editingTranscript) {
            EditTranscriptSheet(initialText: entry.transcript)
        }
        .alert("삭제하시겠습니까?", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) { deleteEntry() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 녹음은 완전히 삭제됩니다.")
        }
        .onAppear {
            editedText = entry.transcript
        }
    }
    
    // MARK: - Sentiment Bar
    
    private var sentimentBar: some View {
        let sentimentName = sentimentLabel
        let sentimentColor = sentimentColor
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("감성 분석")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(sentimentName)
                  .font(.system(size: 12, weight: .medium))
                  .foregroundStyle(sentimentColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                      .fill(.white.opacity(0.08))
                    Rectangle()
                      .fill(sentimentColor)
                      .frame(width: CGFloat(abs(Float(entry.sentiment) / 3.0)) * geo.size.width)
                }
                .frame(height: 4)
                .cornerRadius(2)
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - AI Enrichment
    
    private func generateEnrichment() async {
        isEnriching = true
        showEnrichPanel = true
        
        defer { isEnriching = false }
        
        do {
            let (summary, enrichment) = try await llmService.summarizeTranscript(entry.transcript)
            summaryText = summary
            enrichmentText = enrichment
        } catch {
            enrichmentText = "보강 생성에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Playback
    
    private func startPlayback() {
        isPlaying = true
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.progress < 1.0 {
                self.progress = min(1.0, self.progress + 0.5 / durationSeconds)
            } else {
                self.pausePlayback()
            }
        }
    }
    
    private func pausePlayback() {
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Delete
    
    private func deleteEntry() {
        do {
            databaseManager.mainContext.delete(entry)
            try databaseManager.saveContext()
        } catch {
            print("Failed to delete: \(error)")
        }
        dismiss()
    }
    
    // MARK: - Helpers
    
    private var entryDateText: String {
        entry.recordingDate.formatted(date: .abbreviated, time: .shortened)
    }
    
    private var durationText: String {
        let min = entry.durationMs / 1_000_000
        let sec = (entry.durationMs / 1_000) % 1_000
        return String(format: "%d:%02d", min, sec)
    }
    
    private var entryKeywords: [String] {
        if let data = entry.keywordsJSON.data(using: .utf8),
           let keywords = try? JSONDecoder().decode([String].self, from: data) {
            return keywords
        }
        return []
    }
    
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
    
    private func formatTime(_ seconds: Double) -> String {
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - Subview

                private struct TextButton: View {
        @Binding var isEditing: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 4) {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                      .font(.system(size: 12))
                    Text(isEditing ? "저장" : "편집")
                      .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(AppColors.accent)
            }
        }
    }
    
    
    struct EditTranscriptSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var editedText: String
        @State private var hasChanges: Bool = false
        
        init(initialText: String) {
            self._editedText = State(initialValue: initialText)
        }
        
        var body: some View {
            NavigationStack {
                VStack {
                    TextEditor(text: $editedText)
                      .font(.system(size: 15))
                      .foregroundStyle(.white)
                      .frame(minHeight: 300)
                    
                    HStack {
                        Button("취소") {
                            hasChanges = false
                            dismiss()
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Button("저장하기") {
                            hasChanges = false
                            dismiss()
                        }
                        .buttonStyle(VaultButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .navigationTitle("본문 편집")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    // MARK: - Preview
    
// Preview disabled for compilation compatibility
