import SwiftUI
import CoreData

@MainActor

struct RecordingView: View {
    @StateObject private var sttService = STTService.shared
    @StateObject private var llmService = LocalLLMService.shared
    @StateObject private var databaseManager = DatabaseManager.shared
    
    @State private var timerSeconds: Int = 0
    @State private var timerTimer: Timer?
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showComplete: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var navigationPath: NavigationPath
    
    private var isRecording: Bool { sttService.isRecording }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                
                HStack {
                    Button {
                        dismissRecording()
                    } label: {
                        Image(systemName: "xmark")
                          .font(.system(size: 16, weight: .medium))
                          .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Soul Mining")
                      .font(.system(size: 17, weight: .semibold))
                      .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                      .font(.system(size: 16))
                      .foregroundStyle(AppColors.accent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Spacer(minLength: 0)
                
                // MARK: - Mic Button
                
                VStack(spacing: 20) {
                    // Duration
                    Text(formatDuration(timerSeconds))
                      .font(.system(size: 48, weight: .thin, design: .monospaced))
                      .foregroundStyle(.white)
                    
                    // Pulsing ring when recording
                    ZStack {
                        Circle()
                          .stroke(
                            AppColors.accent.opacity(0.2),
                            lineWidth: isRecording ? 8 : 4
                          )
                          .frame(width: 160, height: 160)
                          .opacity(isRecording ? 0.8 : 0.3)
                        
                        if isRecording {
                            Circle()
                              .stroke(
                                AppColors.accent.opacity(0.1),
                                lineWidth: 12
                              )
                              .frame(width: 180, height: 180)
                              .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isRecording)
                        }
                        
                        Button {
                            if isRecording {
                                stopAndSave()
                            } else {
                                startRecording()
                            }
                        } label: {
                            Circle()
                              .fill(
                                isRecording
                                  ? RadialGradient(colors: [AppColors.danger, AppColors.danger.opacity(0.7)], center: .center, startRadius: 0, endRadius: 75)
                                  : RadialGradient(colors: [AppColors.accent, AppColors.accent.opacity(0.7)], center: .center, startRadius: 0, endRadius: 75)
                              )
                              .frame(width: 140, height: 140)
                              .overlay {
                                  Image(systemName: recordingIcon)
                                    .font(.system(size: isRecording ? 28 : 40))
                                    .foregroundStyle(.white)
                              }
                              .shadow(color: isRecording ? AppColors.danger : AppColors.accent, radius: isRecording ? 20 : 30)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 20)
                    
                    Text(isRecording ? "다시 누르면 저장합니다" : "녹음을 시작하세요")
                      .font(.system(size: 14))
                      .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer(minLength: 16)
                
                // MARK: - Live Transcript
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.bubble")
                          .font(.system(size: 14))
                          .foregroundStyle(AppColors.accent)
                        Text("실시간 텍스트")
                          .font(.system(size: 13, weight: .medium))
                          .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        if sttService.status != .idle {
                            Text(sttService.status.rawValue)
                              .font(.system(size: 11))
                              .foregroundStyle(AppColors.accent.opacity(0.8))
                        }
                    }
                    
                    ScrollView {
                        Text(sttService.currentTranscript.isEmpty
                             ? "여기에 음성이 표시됩니다..."
                             : sttService.currentTranscript)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                          .stroke(.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                
                // MARK: - Status Bar
                
                HStack {
                    if isSaving {
                        ProgressView()
                          .tint(AppColors.accent)
                        Text("저장 중...")
                          .font(.system(size: 13))
                          .foregroundStyle(AppColors.accent)
                    }
                    
                    Spacer()
                    
                    if errorMessage != nil {
                        Image(systemName: "exclamationmark.triangle")
                          .foregroundStyle(AppColors.danger)
                        Text(errorMessage ?? "")
                          .font(.system(size: 12))
                          .foregroundStyle(AppColors.danger)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.top, 8)
            }
        }
        .onChange(of: showComplete) { _, _ in
            if showComplete {
                dismiss()
                showComplete = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func startRecording() {
        errorMessage = nil
        Task {
            do {
                try await sttService.startRecording()
                startTimer()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func stopAndSave() {
        Task {
            do {
                isSaving = true
                try await sttService.stopRecording()
                stopTimer()
                await saveRecording()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
    
    private func saveRecording() async {
        let transcript = sttService.currentTranscript
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "녹음된 텍스트가 없습니다"
            return
        }
        
        guard let title = generateTitle(from: transcript) else {
            errorMessage = "녹음 저장에 실패했습니다"
            return
        }
        
        // Extract keywords & sentiment via AI
        do {
            let (keywords, sentiment) = try await llmService.extractInsights(from: transcript)
            
            let entry = NSEntityDescription.insertNewObject(
                forEntityName: "CLCVoiceLogEntry",
                into: databaseManager.mainContext
            ) as! CLCVoiceLogEntry
            entry.id = UUID().uuidString
            entry.title = title
            entry.recordingDate = Date()
            entry.transcript = transcript
            entry.durationMs = Int32(timerSeconds * 1000)
            entry.sentiment = Int16(sentiment)
            entry.keywordsJSON = keywords.isEmpty ? "[]" : "[\"\(keywords.joined(separator: "\", \""))\"]"
            
            try? databaseManager.saveContext()
        } catch {
            let entry = NSEntityDescription.insertNewObject(
                forEntityName: "CLCVoiceLogEntry",
                into: databaseManager.mainContext
            ) as! CLCVoiceLogEntry
            entry.id = UUID().uuidString
            entry.title = title
            entry.recordingDate = Date()
            entry.transcript = transcript
            entry.durationMs = Int32(timerSeconds * 1000)
            entry.sentiment = Int16(0)
            entry.keywordsJSON = "[]"
            
            try? databaseManager.saveContext()
        }
        
        await MainActor.run {
            showComplete = true
        }
    }
    
    private func dismissRecording() {
        if isRecording {
            Task {
                do {
                    try await sttService.stopRecording()
                } catch {}
                stopTimer()
            }
        }
        dismiss()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerSeconds = 0
        timerTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timerSeconds += 1
        }
    }
    
    private func stopTimer() {
        timerTimer?.invalidate()
        timerTimer = nil
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var recordingIcon: String {
        isRecording ? "stop.fill" : "mic.fill"
    }
    
    private func generateTitle(from transcript: String) -> String? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstSentence = trimmed.split(separator: ".").first.flatMap(String.init) ?? String(trimmed.prefix(30))
        guard !firstSentence.isEmpty else { return nil }
        return firstSentence
    }
    
    // MARK: - STTDelegate
    
    func sttDidUpdateTranscript(_ text: String, isFinal: Bool) {
        // State already updated via STTService.currentTranscript
    }
    
    func sttDidCompleteTranscript(_ text: String) {}
    
    func sttDidChange(isRecording: Bool) {
        // Handled via isRecording computed property
    }
    
    func sttDidFail(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
