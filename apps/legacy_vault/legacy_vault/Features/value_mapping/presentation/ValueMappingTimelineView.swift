import SwiftUI
import CoreData

// MARK: - ValueMappingTimelineView

@MainActor

struct ValueMappingTimelineView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var itemsToDelete: [String] = []
    @State private var selectedItemForEdit: CLCVoiceLogEntry?
    
    private var groups: [String: [CLCVoiceLogEntry]] {
        let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
        fetch.sortDescriptors = [NSSortDescriptor(key: "recordingDate", ascending: false)]
        
        let allEntries = (try? databaseManager.mainContext.fetch(fetch)) ?? []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        let grouped: [String: [CLCVoiceLogEntry]] = Dictionary(grouping: allEntries) { entry in
            formatter.string(from: entry.recordingDate)
        }
        
        var sorted: [String: [CLCVoiceLogEntry]] = [:]
        for key in grouped.keys.sorted(by: >) {
            sorted[key] = grouped[key] ?? []
        }
        return sorted
    }
    
    var groupedEntries: [(date: String, entries: [CLCVoiceLogEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        return groups.map { key, entries in
            let parts = key.components(separatedBy: "-")
            let dateStr = parts.count >= 2 ? "\(parts[0]).(\(parts[1]))" : key
            return (dateStr, entries)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if groupedEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(groupedEntries, id: \.date) { group in
                                TimelineGroup(dateLabel: group.date, entries: group.entries)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("타임라인")
            .navigationBarTitleDisplayMode(.inline)
            .alert("삭제 확인", isPresented: $showingAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    deleteItems()
                }
            } message: {
                Text("이 항목들을 삭제하시겠습니까?")
            }
            .overlay {
                if !itemsToDelete.isEmpty {
                    Color.clear
                      .onAppear {
                          showingAlert = true
                      }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
              .font(.system(size: 40))
              .foregroundStyle(.white.opacity(0.2))
            Text("타임라인에 표시할\n녹음 기록이 없어요")
              .font(.system(size: 15))
              .foregroundStyle(.white.opacity(0.4))
              .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        itemsToDelete = offsets.map { idx in
            var runningIdx = 0
            for group in groupedEntries {
                if idx >= runningIdx && idx < runningIdx + group.entries.count {
                    return group.entries[idx - runningIdx].id
                }
                runningIdx += group.entries.count
            }
            return ""
        }
    }
    
    private func deleteItems() {
        for id in itemsToDelete {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entry = (try? databaseManager.mainContext.fetch(fetch))?.first {
                databaseManager.delete(entry)
            }
        }
        itemsToDelete.removeAll()
    }
}

// MARK: - Timeline Group

// MARK: - Timeline Group

private struct TimelineGroup: View {
    let dateLabel: String
    let entries: [CLCVoiceLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineDateHeader(date: dateLabel, count: entries.count)
            
            ForEach(entries, id: \.objectID) { entry in
                TimelineCard(entry: entry)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Timeline Date Header

private struct TimelineDateHeader: View {
    let date: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
              .fill(AppColors.accent.opacity(0.3))
              .frame(width: 10, height: 10)
            
            Text(date)
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(.white)
            
            Text("(\(count)개)")
              .font(.system(size: 12))
              .foregroundStyle(.white.opacity(0.5))
            
            Spacer()
            
            Rectangle()
              .fill(.white.opacity(0.1))
              .frame(width: 40, height: 1)
        }
    }
}

// MARK: - Timeline Card

private struct TimelineCard: View {
    let entry: CLCVoiceLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: title + timestamp + sentiment
            cardHeader
            
            // Transcript preview
            if !entry.transcript.isEmpty {
                Text(entry.transcript)
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.7))
                  .lineLimit(3)
                  .lineSpacing(4)
            }
            
            // Tags
            if !entry.keywordsJSON.isEmpty {
                keywordChips
            }
            
            // AI summary
            if let summary = entry.aiSummary, !summary.isEmpty {
                aiSummaryBox
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button(role: .destructive) {
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
    
    private var cardHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
              .font(.system(size: 14))
              .foregroundStyle(categoryColor)
            
            Text(entry.title)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(.white)
            
            Spacer()
            
            HStack(spacing: 8) {
                sentimentBadge
                Text(formatShortDate(entry.recordingDate))
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
    
    private var sentimentBadge: some View {
        switch Int(entry.sentiment) {
        case 3:
            return Image(systemName: "heart.circle.fill")
              .foregroundStyle(AppColors.neonPink)
              .font(.system(size: 13))
              .help("매우 좋음")
        case 2:
            return Image(systemName: "star.circle.fill")
              .foregroundStyle(AppColors.accent)
              .font(.system(size: 13))
              .help("좋음")
        case 1:
            return Image(systemName: "plus.circle.fill")
              .foregroundStyle(.green)
              .font(.system(size: 13))
              .help("다소 좋음")
        case 0:
            return Image(systemName: "minus.circle.fill")
              .foregroundStyle(AppColors.warning)
              .font(.system(size: 13))
              .help("중립")
        case -1:
            return Image(systemName: "arrow.down.circle.fill")
              .foregroundStyle(.orange)
              .font(.system(size: 13))
              .help("다소 나쁨")
        case -2, -3:
            return Image(systemName: "arrow.down.double.circle.fill")
              .foregroundStyle(AppColors.danger)
              .font(.system(size: 13))
              .help("나쁨")
        default:
            return Image(systemName: "circle")
              .foregroundStyle(.white.opacity(0.4))
              .font(.system(size: 13))
              .help("감정 없음")
        }
    }
    
    private var categoryColor: Color {
        switch entry.sentiment {
        case 2, 3: return AppColors.accent
        case 1: return .green
        case 0: return AppColors.warning
        case -1: return .orange
        case -2, -3: return AppColors.danger
        default: return .white.opacity(0.6)
        }
    }
    
    private var keywordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text("#\(entry.keywordsJSON.trimmingCharacters(in: .whitespacesAndNewlines))")
                      .font(.system(size: 11))
                      .foregroundStyle(AppColors.neonCyan)
                      .padding(.horizontal, 8)
                      .padding(.vertical, 3)
                  .background(AppColors.neonCyan.opacity(0.1), in: Capsule())
                }
        }
    }
    
    private var aiSummaryBox: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkle")
              .foregroundStyle(AppColors.neonPink)
              .font(.system(size: 13))
            
            Text(entry.aiSummary!)
              .font(.system(size: 12))
              .foregroundStyle(.white.opacity(0.65))
              .lineLimit(2)
        }
        .padding(10)
        .background(AppColors.neonPink.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
// MARK: - Preview

// Preview disabled for compilation compatibility
