import SwiftUI
import CoreData

// MARK: - KeywordCloudView

@MainActor

struct KeywordCloudView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @State private var selectedKeyword: CLCValueKeyword?
    @State private var showContextSheet: Bool = false
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var keywords: [CLCValueKeyword] {
        let fetch = CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
        fetch.sortDescriptors = [NSSortDescriptor(key: "frequency", ascending: false)]
        return (try? databaseManager.mainContext.fetch(fetch)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if keywords.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(keywords, id: \.objectID) { keyword in
                                CloudKeywordChip(
                                    keyword: keyword,
                                    color: categoryColor(keyword.category),
                                    maxFrequency: maxFrequency,
                                    action: {
                                        selectedKeyword = keyword
                                        showContextSheet = true
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("핵심 가치")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showContextSheet) {
                if let keyword = selectedKeyword {
                    KeywordContextSheet(keyword: keyword)
                }
            }
        }
    }
    
    private var maxFrequency: Int {
        keywords.map { Int($0.frequency) }.max() ?? 1
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun")
              .font(.system(size: 40))
              .foregroundStyle(.white.opacity(0.2))
            Text("아직 가치 분석이\n생성되지 않았어요")
              .font(.system(size: 15))
              .foregroundStyle(.white.opacity(0.4))
              .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "family": return AppColors.neonPink
        case "career": return AppColors.neonCyan
        case "emotion": return .yellow
        case "challenge": return AppColors.warning
        case "peace": return .green
        case "growth": return AppColors.accent
        default: return .white
        }
    }
}

// MARK: - Cloud Keyword Chip

                private struct CloudKeywordChip: View {
    let keyword: CLCValueKeyword
    let color: Color
    let maxFrequency: Int
    let action: () -> Void
    
    private var fontSize: CGFloat {
        let ratio = maxFrequency > 0 ? Double(keyword.frequency) / Double(maxFrequency) : 0
        return 14 + (ratio * 32)
    }
    
    private var chipScale: CGFloat {
        let ratio = maxFrequency > 0 ? Double(keyword.frequency) / Double(maxFrequency) : 0
        return 0.85 + (ratio * 0.4)
    }
    
    var body: some View {
        Button(action: action) {
            Text(keyword.word)
              .font(.system(size: fontSize, weight: .medium))
              .foregroundStyle(color)
              .padding(.horizontal, 16 + Double(fontSize) * 0.5)
              .padding(.vertical, 10 + Double(fontSize) * 0.25)
              .background(
                color.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 24)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 24)
                  .stroke(color.opacity(0.3), lineWidth: 1)
              )
              .scaleEffect(chipScale)
              .shadow(color: color.opacity(0.15), radius: 6, y: 2)
        }
    }
}

// MARK: - Keyword Context Sheet

                private struct KeywordContextSheet: View {
    let keyword: CLCValueKeyword
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var databaseManager = DatabaseManager.shared
    
    private var relatedVoices: [CLCVoiceLogEntry] {
        let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
        fetch.predicate = NSPredicate(format: "keywordsJSON contains[c] %@", keyword.word)
        fetch.sortDescriptors = [NSSortDescriptor(key: "recordingDate", ascending: false)]
        return (try? databaseManager.mainContext.fetch(fetch)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Keyword header
                    keywordHeader
                    
                    // Related recordings
                    relatedVoicesHeader
                    if relatedVoices.isEmpty {
                        Text("관련 녹음 기록이 없습니다")
                          .font(.system(size: 14))
                          .foregroundStyle(.white.opacity(0.5))
                          .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(relatedVoices, id: \.objectID) { entry in
                                RelatedVoiceCell(entry: entry)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(keyword.word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                      .foregroundStyle(AppColors.accent)
                }
            }
        }
    }
    
    private var keywordHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                  .fill(categoryColor.opacity(0.15))
                  .frame(width: 48, height: 48)
                Text(keyword.word.prefix(1))
                  .font(.system(size: 22, weight: .bold))
                  .foregroundStyle(categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(keyword.word)
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundStyle(.white)
                Text("빈도: \(keyword.frequency)회 • \(categoryDescription)")
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var categoryColor: Color {
        switch keyword.category {
        case "family": return AppColors.neonPink
        case "career": return AppColors.neonCyan
        case "emotion": return .yellow
        case "challenge": return AppColors.warning
        case "peace": return .green
        case "growth": return AppColors.accent
        default: return .white
        }
    }
    
    private var categoryDescription: String {
        switch keyword.category {
        case "family": return "가족 & 관계"
        case "career": return "직업 & 사업"
        case "emotion": return "감정 & 느낌"
        case "challenge": return "어려움 & 도전"
        case "peace": return "평화 & 안식"
        case "growth": return "성장 & 학습"
        default: return "기타"
        }
    }
    
    private var relatedVoicesHeader: some View {
        HStack {
            Text("관련 녹음 기록")
              .font(.system(size: 15, weight: .semibold))
              .foregroundStyle(.white)
            Spacer()
            Badge(text: "\(relatedVoices.count)")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.white)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(AppColors.accent.opacity(0.3), in: Capsule())
        }
    }
}

// MARK: - Related Voice Cell

                private struct RelatedVoiceCell: View {
    let entry: CLCVoiceLogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Mic icon with sentiment color
            ZStack {
                Circle()
                  .fill(sentimentColor.opacity(0.15))
                  .frame(width: 40, height: 40)
                Image(systemName: "mic.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(sentimentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                Text(formatDate(entry.recordingDate))
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            sentimentIndicator
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var sentimentColor: Color {
        switch Int(entry.sentiment) {
        case 2, 3: return AppColors.accent
        case 1: return .green
        case 0: return AppColors.warning
        case -1: return .orange
        case -2, -3: return AppColors.danger
        default: return .white.opacity(0.5)
        }
    }
    
    @ViewBuilder
    private var sentimentIndicator: some View {
        switch Int(entry.sentiment) {
        case 3: Image(systemName: "heart.fill").foregroundStyle(AppColors.neonPink).font(.system(size: 14))
        case 2: Image(systemName: "star.fill").foregroundStyle(AppColors.accent).font(.system(size: 14))
        case 1: Image(systemName: "plus.circle.fill").foregroundStyle(.green).font(.system(size: 14))
        case 0: Image(systemName: "minus.circle.fill").foregroundStyle(AppColors.warning).font(.system(size: 14))
        case -1: Image(systemName: "exclamation.triangle.fill").foregroundStyle(.orange).font(.system(size: 14))
        case -2, -3: Image(systemName: "xmark.circle.fill").foregroundStyle(AppColors.danger).font(.system(size: 14))
        default: EmptyView()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// MARK: - Badge

                private struct Badge: View {
    let text: String
    
    var body: some View {
        Text(text)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(.white.opacity(0.1), in: Capsule())
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
