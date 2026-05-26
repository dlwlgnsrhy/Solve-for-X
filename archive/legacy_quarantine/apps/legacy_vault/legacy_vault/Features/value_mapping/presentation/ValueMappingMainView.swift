import SwiftUI
import CoreData

// MARK: - ValueMappingMainView

@MainActor

struct ValueMappingMainView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @State private var selectedTab: Int = 0
    
    var totalKeywords: Int {
        let fetch = NSFetchRequest<CLCValueKeyword>(entityName: "CLCValueKeyword")
        return (try? databaseManager.mainContext.fetch(fetch))?.count ?? 0
    }
    
    var mostFrequentKeyword: CLCValueKeyword? {
        let fetch = CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
        fetch.sortDescriptors = [NSSortDescriptor(key: "frequency", ascending: false)]
        fetch.fetchLimit = 1
        return (try? databaseManager.mainContext.fetch(fetch))?.first
    }
    
    var predominantCategory: String {
        let fetch = CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
        guard let keywords = try? databaseManager.mainContext.fetch(fetch) else { return "—" }
        
        let categoryCounts: [String: Int] = Dictionary(grouping: keywords) { $0.category }.mapValues { $0.count }
        return categoryCounts.max { $0.value < $1.value }?.key ?? "—"
    }
    
    var averageSentiment: Double {
        let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
        guard let entries = try? databaseManager.mainContext.fetch(fetch), !entries.isEmpty else { return 0 }
        let sum = entries.reduce(0) { $0 + Double($1.sentiment) }
        return sum / Double(entries.count)
    }
    
    var sentimentTrend: SentimentTrend {
        let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
        fetch.sortDescriptors = [NSSortDescriptor(key: "recordingDate", ascending: true)]
        fetch.fetchLimit = 10
        guard let entries = try? databaseManager.mainContext.fetch(fetch), entries.count >= 2 else {
            return .neutral
        }
        
        let firstHalf = entries.prefix(entries.count / 2)
        let secondHalf = entries.suffix(entries.count / 2)
        
        let firstAvg = firstHalf.reduce(0) { $0 + Double($1.sentiment) } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + Double($1.sentiment) } / Double(secondHalf.count)
        
        let diff = secondAvg - firstAvg
        if diff > 0.5 { return .rising }
        if diff < -0.5 { return .falling }
        return .neutral
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        overviewHeader
                        statsGrid
                        subFeatureCards
                        sentimentTrendCard
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("가치 분석")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Overview Header
    
    private var overviewHeader: some View {
        VStack(spacing: 12) {
            if let keyword = mostFrequentKeyword {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                          .fill(AppColors.neonPink.opacity(0.15))
                          .frame(width: 64, height: 64)
                        VStack(spacing: 2) {
                            Image(systemName: "crown.fill")
                              .font(.system(size: 18))
                              .foregroundStyle(AppColors.neonPink)
                            Text("\(Int(keyword.frequency))")
                              .font(.system(size: 20, weight: .bold))
                              .foregroundStyle(AppColors.neonPink)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("가장 많이 나타난价值")
                          .font(.system(size: 13))
                          .foregroundStyle(.white.opacity(0.6))
                        
                        HStack(spacing: 6) {
                            Text("\"\(keyword.word)\"")
                              .font(.system(size: 18, weight: .bold))
                              .foregroundStyle(AppColors.neonPink)
                            Text("(\(categoryLabel(for: keyword.category)))")
                              .font(.system(size: 13))
                              .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(AppColors.neonPink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(AppColors.neonPink.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        HStack(spacing: 8) {
            StatCard(
                icon: "hash",
                title: "전체 키워드",
                value: "\(totalKeywords)",
                color: AppColors.accent
            )
            StatCard(
                icon: "tag.fill",
                title: "주요 카테고리",
                value: categoryLabel(for: predominantCategory),
                color: AppColors.neonCyan,
                size: .compact
            )
            StatCard(
                icon: "chart.bar.fill",
                title: "평균 감정",
                value: sentimentLabel(),
                color: averageSentiment >= 0 ? AppColors.accent : AppColors.danger,
                size: .compact
            )
        }
    }
    
    // MARK: - Sub Feature Cards
    
    private var subFeatureCards: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: ValueMapView()) {
                SubFeatureCard(
                    icon: "map.fill",
                    title: "가치지도",
                    subtitle: "모든 가치 키워드를 카테고리별로 확인",
                    color: AppColors.accent
                )
            }
            
            NavigationLink(destination: KeywordCloudView()) {
                SubFeatureCard(
                    icon: "cloud.fill",
                    title: "핵심 가치 클라우드",
                    subtitle: "빈도 기반 시각적 가치 분석",
                    color: AppColors.neonCyan
                )
            }
            
            NavigationLink(destination: ValueMappingTimelineView()) {
                SubFeatureCard(
                    icon: "line.3.horizontal.decrease.circle.fill",
                    title: "타임라인",
                    subtitle: "날짜별 가치 변화를 추적",
                    color: .white.opacity(0.5)
                )
            }
        }
    }
    
    // MARK: - Sentiment Trend Card
    
    private var sentimentTrendCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("감정 흐름")
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(.white)
                Text(trendDescription)
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            sentimentTrendIcon
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
    
    private var trendDescription: String {
        switch sentimentTrend {
        case .rising: return "최근 기록에서 긍정적 경향이 강화되고 있어요"
        case .falling: return "최근 기록에서 어려운 감정들이 나타나요"
        case .neutral: return "감정적으로 일정한 패턴을 보여요"
        }
    }
    
    private var sentimentTrendIcon: some View {
        ZStack {
            Circle()
              .fill(sentimentTrend.color.opacity(0.15))
              .frame(width: 44, height: 44)
            Image(systemName: sentimentTrend.icon)
              .font(.system(size: 20))
              .foregroundStyle(sentimentTrend.color)
        }
    }
    
    // MARK: - Helpers
    
    private func categoryLabel(for category: String) -> String {
        switch category {
        case "family": return "가족"
        case "career": return "직업"
        case "emotion": return "감정"
        case "challenge": return "어려움"
        case "peace": return "평화"
        case "growth": return "성장"
        default: return category
        }
    }
    
    private func sentimentLabel() -> String {
        switch Int(averageSentiment.rounded()) {
        case 3: return "매우 좋음"
        case 2: return "좋음"
        case 1: return "다소 좋음"
        case 0: return "중립"
        case -1: return "다소 나쁨"
        case -2: return "나쁨"
        case -3: return "매우 나쁨"
        default: return "—"
        }
    }
}

// MARK: - Stat Card

                private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let size: CardSize
    
    enum CardSize { case normal, compact }
    
    init(
        icon: String,
        title: String,
        value: String,
        color: Color,
        size: CardSize = .normal
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.color = color
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
              .font(.system(size: size == .compact ? 14 : 20))
              .foregroundStyle(color)
            
            Text(value)
              .font(.system(size: size == .compact ? 16 : 22, weight: .bold))
              .foregroundStyle(color)
            
            Text(title)
              .font(.system(size: 11))
              .foregroundStyle(.white.opacity(0.6))
              .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sub Feature Card

                private struct SubFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                  .fill(color.opacity(0.1))
                  .frame(width: 48, height: 48)
                Image(systemName: icon)
                  .font(.system(size: 22))
                  .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(.white)
                Text(subtitle)
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.55))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.3))
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Sentiment Trend

enum SentimentTrend: Comparable {
    case falling, neutral, rising
    
    static func < (lhs: SentimentTrend, rhs: SentimentTrend) -> Bool {
        switch (lhs, rhs) {
        case (.falling, _): return true
        case (_, .rising): return true
        default: return false
        }
    }
    
    var icon: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .neutral: return "minus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .rising: return AppColors.accent
        case .falling: return AppColors.danger
        case .neutral: return AppColors.warning
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
