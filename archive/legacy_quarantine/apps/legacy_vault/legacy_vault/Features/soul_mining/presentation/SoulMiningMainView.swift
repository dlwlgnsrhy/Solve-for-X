import SwiftUI
import CoreData

@MainActor

struct SoulMiningMainView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    
    @State private var recentEntries: [CLCVoiceLogEntry] = []
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            NavigationStack(path: $navigationPath) {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        
                        quickStartCard
                        
                        statsSection
                        
                        HStack {
                            Text("최근 녹음")
                              .font(.system(size: 16, weight: .semibold))
                              .foregroundStyle(.white)
                            Spacer()
                            
                            NavigationLink {
                                SoulMiningSummaryView()
                            } label: {
                                Image(systemName: "chart.bar.fill")
                                  .font(.system(size: 16))
                                  .foregroundStyle(AppColors.accent)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if recentEntries.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                ForEach(Array(recentEntries.prefix(6).enumerated()), id: \.element.objectID) { _, entry in
                                    recentEntryRow(entry)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 24)
                    }
                }
                .navigationTitle("Soul Mining")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(AppColors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .task {
            loadEntries()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Soul Mining")
                  .font(.system(size: 22, weight: .bold))
                  .foregroundStyle(.white)
                Text("당신의 이야기를 음성으로 남기세요")
                  .font(.system(size: 14))
                  .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Quick Start Card
    
    private var quickStartCard: some View {
        NavigationLink {
            RecordingView(navigationPath: $navigationPath)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("새 녹음 시작")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(.white)
                    Text("지금 당신의 이야기를 남겨보세요")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "mic.fill")
                  .font(.system(size: 24))
                  .foregroundStyle(AppColors.accent)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(AppColors.accent.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Stats
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            statTile(
                label: "총 녹음",
                value: String(allRecordingCount),
                icon: "mic.fill"
            )
            
            Divider()
              .foregroundStyle(.white.opacity(0.1))
            
            statTile(
                label: "총 시간",
                value: totalDurationFormatted,
                icon: "clock.fill"
            )
            
            Divider()
              .foregroundStyle(.white.opacity(0.1))
            
            statTile(
                label: "상위 키워드",
                value: topKeywordText,
                icon: "tag.fill"
            )
        }
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    private func statTile(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
              .font(.system(size: 16))
              .foregroundStyle(AppColors.accent)
            Text(value)
              .font(.system(size: 18, weight: .bold))
              .foregroundStyle(.white)
            Text(label)
              .font(.system(size: 11))
              .foregroundStyle(.white.opacity(0.4))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "record.circle")
              .font(.system(size: 48))
              .foregroundStyle(.white.opacity(0.1))
            Text("아직 녹음이 없습니다")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.3))
            Text("녹음 시작하기 버튼을 눌러\n당신의 이야기를 시작하세요")
              .font(.system(size: 13))
              .foregroundStyle(.white.opacity(0.2))
              .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Recent Entry Row
    
    private func recentEntryRow(_ entry: CLCVoiceLogEntry) -> some View {
        NavigationLink {
            VoicePlayerView(entry: entry)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.title)
                      .font(.system(size: 14, weight: .medium))
                      .foregroundStyle(.white)
                    Spacer()
                    Text(formatEntryDate(entry.recordingDate))
                      .font(.system(size: 11))
                      .foregroundStyle(.white.opacity(0.4))
                }
                
                if let keywords = parseKeywords(entry.keywordsJSON), !keywords.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(keywords, id: \.self) { kw in
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
                    Text(formatDurationMs(Int(entry.durationMs)))
                      .font(.system(size: 11))
                      .foregroundStyle(.white.opacity(0.4))
                    
                    Spacer()
                    
                    if entry.sentiment > 0 {
                        Text("긍정")
                          .font(.system(size: 11))
                          .foregroundStyle(AppColors.accent.opacity(0.7))
                    }
                }
            }
            .padding(10)
            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Data Loading
    
    private func loadEntries() {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            fetch.sortDescriptors = [
                NSSortDescriptor(keyPath: \CLCVoiceLogEntry.recordingDate, ascending: false)
            ]
            recentEntries = try databaseManager.mainContext.fetch(fetch)
        } catch {
            recentEntries = []
        }
    }
    
    private var allRecordingCount: Int {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            return try databaseManager.mainContext.fetch(fetch).count
        } catch {
            return 0
        }
    }
    
    private var totalDurationFormatted: String {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            let entries = try databaseManager.mainContext.fetch(fetch)
            let totalMs = entries.reduce(0) { $0 + Int($1.durationMs) }
            return formatDurationMs(totalMs)
        } catch {
            return "0:00"
        }
    }
    
    private var topKeywordText: String {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            let entries = try databaseManager.mainContext.fetch(fetch)
            var counts: [String: Int] = [:]
            for entry in entries {
                if let keywords = parseKeywords(entry.keywordsJSON) {
                    for kw in keywords {
                        counts[kw, default: 0] += 1
                    }
                }
            }
            guard let top = counts.max(by: { $0.value < $1.value })?.key, !top.isEmpty else {
                return "-"
            }
            return top.prefix(6).description
        } catch {
            return "-"
        }
    }
    
    // MARK: - Helpers
    
    private func formatEntryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatDurationMs(_ totalMs: Int) -> String {
        let totalSec = totalMs / 1000
        let min = totalSec / 60
        let sec = totalSec % 60
        if min > 0 {
            return String(format: "%d:%02d", min, sec)
        }
        return "\(sec)초"
    }
    
    private func parseKeywords(_ json: String) -> [String]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}

// Preview disabled for compilation compatibility
