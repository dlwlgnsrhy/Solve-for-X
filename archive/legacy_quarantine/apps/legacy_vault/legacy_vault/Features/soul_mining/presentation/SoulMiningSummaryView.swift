import SwiftUI
import CoreData

@MainActor

struct SoulMiningSummaryView: View {
    @StateObject private var llmService = LocalLLMService.shared
    @StateObject private var databaseManager = DatabaseManager.shared
    
    @State private var allEntries: [CLCVoiceLogEntry] = []
    @State private var summaryText: String = ""
    @State private var isGeneratingSummary: Bool = false
    @State private var allKeywords: [(String, Int)] = []
    @State private var shareText: String = ""
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerSection
                    
                    // Stats cards
                    statsCards
                    
                    // AI Summary
                    aISummaryCard
                    
                    // Keywords cloud
                    keywordsSection
                    
                    // Recordings list
                    recordingsList
                    
                    // Share button
                    shareSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .task {
            loadEntries()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "mic.fill")
              .font(.system(size: 36))
              .foregroundStyle(AppColors.accent)
            
            Text("Soul Mining 기록")
              .font(.system(size: 22, weight: .bold))
              .foregroundStyle(.white)
            
            Text("\(allEntries.count)개의 녹음")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    // MARK: - Stats
    
    private var statsCards: some View {
        HStack(spacing: 10) {
            statCard(
                value: "\(allEntries.count)",
                label: "녹음",
                icon: "mic.fill"
            )
            
            statCard(
                value: totalDurationText,
                label: "총 시간",
                icon: "clock.fill"
            )
            
            statCard(
                value: "\(allKeywords.count)",
                label: "키워드",
                icon: "tag.fill"
            )
        }
    }
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
              .font(.system(size: 18))
              .foregroundStyle(AppColors.accent)
            
            Text(value)
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(.white)
            
            Text(label)
              .font(.system(size: 11))
              .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var totalDurationText: String {
        let totalMs = allEntries.reduce(0) { $0 + Int($1.durationMs) }
        let totalSec = totalMs / 1000
        let min = totalSec / 60
        let sec = totalSec % 60
        if min > 0 {
            return String(format: "%d분%d초", min, sec)
        }
        return "\(sec)초"
    }
    
    // MARK: - AI Summary
    
    private var aISummaryCard: some View {
        Button {
            generateSummary()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                      .font(.system(size: 16))
                      .foregroundStyle(AppColors.neonCyan)
                    Text("AI 전체 요약")
                      .font(.system(size: 14, weight: .semibold))
                      .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if isGeneratingSummary {
                        ProgressView()
                          .tint(AppColors.neonCyan)
                    }
                }
                
                if !summaryText.isEmpty {
                    Text(summaryText)
                      .font(.system(size: 14))
                      .foregroundStyle(.white.opacity(0.8))
                      .lineSpacing(3)
                } else if isGeneratingSummary {
                    ProgressView("요약 생성 중...")
                      .tint(AppColors.neonCyan)
                } else {
                    Text("모든 녹음의 핵심을 AI가 정리해 드립니다.")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.neonCyan.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(AppColors.neonCyan.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Keywords
    
    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "tag")
                  .font(.system(size: 14))
                  .foregroundStyle(AppColors.accent)
                Text("추출된 키워드")
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allKeywords.filter { $0.1 > 0 }, id: \.0) { kw in
                        keywordChip(word: kw.0, count: kw.1)
                    }
                }
            }
        }
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func keywordChip(word: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(word)
              .font(.system(size: 13, weight: .medium))
            Text("(\(count))")
              .font(.system(size: 11))
              .foregroundStyle(AppColors.accent.opacity(0.7))
        }
        .foregroundStyle(AppColors.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.accent.opacity(0.08), in: Capsule())
    }
    
    // MARK: - Recordings List
    
    private var recordingsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("녹음 목록")
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                
                Spacer()
            }
            
            if allEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "record.circle")
                      .font(.system(size: 36))
                      .foregroundStyle(.white.opacity(0.15))
                    Text("아직 녹음이 없습니다.")
                      .font(.system(size: 14))
                      .foregroundStyle(.white.opacity(0.3))
                }
                .padding(24)
            } else {
                ForEach(allEntries.sorted(by: { $0.recordingDate > $1.recordingDate }), id: \.objectID) { entry in
                    recordingRow(entry)
                }
            }
        }
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func recordingRow(_ entry: CLCVoiceLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.title)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(.white)
                Spacer()
                Text(entryDateText(entry))
                  .font(.system(size: 11))
                  .foregroundStyle(.white.opacity(0.4))
            }
            
            if !entryKeywords(entry).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entryKeywords(entry), id: \.self) { kw in
                            Text(kw)
                              .font(.system(size: 11))
                              .foregroundStyle(AppColors.accent)
                              .padding(.horizontal, 6)
                              .padding(.vertical, 2)
                              .background(AppColors.accent.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
            
            HStack {
                Text(durationText(entry))
                  .font(.system(size: 11))
                  .foregroundStyle(.white.opacity(0.4))
                
                Spacer()
                
                if entry.sentiment > 0 {
                    Text(entrySentimentEmoji)
                      .font(.system(size: 12))
                }
            }
        }
        .padding(10)
        .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Share
    
    private var shareSection: some View {
        Button {
            generateShareText()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                  .font(.system(size: 16))
                
                Text("기록 내보내기")
                  .font(.system(size: 15, weight: .semibold))
                
                Spacer()
            }
            .foregroundStyle(AppColors.background)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func generateShareText() {
        var text = "🌱 Soul Mining 기록\n\n"
        
        if !summaryText.isEmpty {
            text += "\(summaryText)\n\n"
        }
        
        text += "---\n\n녹음 목록:\n\n"
        
        for entry in allEntries.sorted(by: { $0.recordingDate > $1.recordingDate }) {
            text += "• \(entry.title) (\(entryDateText(entry)))\n"
            if !entryKeywords(entry).isEmpty {
                text += "  키워드: \(entryKeywords(entry).joined(separator: ","))\n"
            }
        }
        
        shareText = text
    }
    
    // MARK: - Data Loading
    
    private func loadEntries() {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \CLCVoiceLogEntry.recordingDate, ascending: false)]
            allEntries = try databaseManager.mainContext.fetch(fetch)
            
            // Aggregate keywords
            var keywordCounts: [String: Int] = [:]
            for entry in allEntries {
                if let data = entry.keywordsJSON.data(using: .utf8),
                   let keywords = try? JSONDecoder().decode([String].self, from: data) {
                    for kw in keywords {
                        keywordCounts[kw, default: 0] += 1
                    }
                }
            }
            allKeywords = keywordCounts.sorted(by: { $0.value > $1.value })
        } catch {}
    }
    
    private func generateSummary() {
        isGeneratingSummary = true
        
        Task {
            do {
                let transcripts = allEntries.map { $0.transcript }.joined(separator: "\n---\n")
                let (summary, _) = try await llmService.summarizeTranscript(transcripts)
                summaryText = summary
            } catch {
                summaryText = "요약 생성에 실패했습니다."
            }
            isGeneratingSummary = false
        }
    }
    
    // MARK: - Helpers
    
    private func entryDateText(_ entry: CLCVoiceLogEntry) -> String {
        entry.recordingDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func durationText(_ entry: CLCVoiceLogEntry) -> String {
        let totalSec = Int(entry.durationMs) / 1000
        let min = totalSec / 60
        let sec = totalSec % 60
        return String(format: "%d:%02d", min, sec)
    }
    
    private var entrySentimentEmoji: String {
        switch allEntries.last?.sentiment ?? 0 {
        case let s where s > 1: return "😊"
        case let s where s < -1: return "😢"
        default: return "😐"
        }
    }
    
    private func entryKeywords(_ entry: CLCVoiceLogEntry) -> [String] {
        if let data = entry.keywordsJSON.data(using: .utf8),
           let keywords = try? JSONDecoder().decode([String].self, from: data) {
            return keywords
        }
        return []
    }
}

// Preview disabled for compilation compatibility
