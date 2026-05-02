import SwiftUI
import CoreData

// MARK: - ValueMapView

@MainActor

struct ValueMapView: View {
    @StateObject private var databaseManager = DatabaseManager.shared
    @State private var selectedFilter: KeywordCategoryFilter = .all
    @State private var showEditFrequency: Bool = false
    @State private var editingKeyword: CLCValueKeyword?
    @State private var editFrequency: Int = 0
    
    var filteredKeywords: [CLCValueKeyword] {
        let fetch = CLCValueKeyword.fetchRequest() as! NSFetchRequest<CLCValueKeyword>
        fetch.sortDescriptors = [NSSortDescriptor(key: "frequency", ascending: false)]
        
        guard selectedFilter != .all else {
            return (try? databaseManager.mainContext.fetch(fetch)) ?? []
        }
        
        let predicate = NSPredicate(format: "category == %@", selectedFilter.rawValue)
        fetch.predicate = predicate
        return (try? databaseManager.mainContext.fetch(fetch)) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    categoryFilterStrip
                    Divider().background(.white.opacity(0.08))
                    
                    if filteredKeywords.isEmpty {
                        emptyState
                    } else {
                        KeywordList(keywords: filteredKeywords)
                            .environmentObject(DatabaseManager.shared)
                    }
                }
            }
            .navigationTitle("가치지도")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedFilter = .all
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                          .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showEditFrequency) {
                if let keyword = editingKeyword {
                    EditFrequencySheet(
                        keyword: keyword,
                        frequency: $editFrequency,
                        onSave: { updatedFreq in
                            saveFrequency(for: keyword, frequency: updatedFreq)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Category Filter Strip
    
    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryFilterButton(
                    title: "전체",
                    icon: "list.bullet",
                    isSelected: selectedFilter == .all,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .all
                        }
                    }
                )
                CategoryFilterButton(
                    title: "가족",
                    icon: "person.2.fill",
                    category: .family,
                    isSelected: selectedFilter == .family,
                    color: AppColors.neonPink,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .family
                        }
                    }
                )
                CategoryFilterButton(
                    title: "직업",
                    icon: "briefcase.fill",
                    category: .career,
                    isSelected: selectedFilter == .career,
                    color: AppColors.neonCyan,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .career
                        }
                    }
                )
                CategoryFilterButton(
                    title: "감정",
                    icon: "face.smiling.fill",
                    category: .emotion,
                    isSelected: selectedFilter == .emotion,
                    color: .yellow,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .emotion
                        }
                    }
                )
                CategoryFilterButton(
                    title: "어려움",
                    icon: "arrow.uturn.right.circle.fill",
                    category: .challenge,
                    isSelected: selectedFilter == .challenge,
                    color: AppColors.warning,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .challenge
                        }
                    }
                )
                CategoryFilterButton(
                    title: "평화",
                    icon: "sparkle",
                    category: .peace,
                    isSelected: selectedFilter == .peace,
                    color: .green,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .peace
                        }
                    }
                )
                CategoryFilterButton(
                    title: "성장",
                    icon: "leaf.fill",
                    category: .growth,
                    isSelected: selectedFilter == .growth,
                    color: AppColors.accent,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = .growth
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AppColors.background)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 40))
              .foregroundStyle(.white.opacity(0.2))
            Text("선택한 카테고리엔\n저장된 가치가 없어요")
              .font(.system(size: 15))
              .foregroundStyle(.white.opacity(0.4))
              .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func openEditFrequency(_ keyword: CLCValueKeyword) {
        editingKeyword = keyword
        editFrequency = Int(keyword.frequency)
        showEditFrequency = true
    }
    
    private func saveFrequency(for keyword: CLCValueKeyword, frequency: Int) {
        keyword.frequency = Int32(frequency)
        do {
            try databaseManager.saveContext()
        } catch {
            print("Failed to save keyword frequency: \(error)")
        }
    }
}

// MARK: - Category Enum

enum KeywordCategoryFilter: String {
    case all
    case family
    case career
    case emotion
    case challenge
    case peace
    case growth
}

// MARK: - Category Filter Button

                private struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let category: KeywordCategoryFilter?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        category: KeywordCategoryFilter? = nil,
        isSelected: Bool,
        color: Color = AppColors.accent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.category = category
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                  .font(.system(size: 12))
                Text(title)
                  .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? color.opacity(0.2) : .white.opacity(0.06),
                in: Capsule()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                  .stroke(color.opacity(isSelected ? 0.6 : 0.0), lineWidth: 1)
            )
        }
    }
}

// MARK: - Keyword List

                private struct KeywordList: View {
    let keywords: [CLCValueKeyword]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(keywords, id: \.objectID) { keyword in
                    KeywordRow(
                        keyword: keyword,
                        color: categoryColor(keyword.category),
                        frequency: Int(keyword.frequency)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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

// MARK: - Keyword Row

                private struct KeywordRow: View {
    let keyword: CLCValueKeyword
    let color: Color
    let frequency: Int
    
    var body: some View {
        HStack(spacing: 14) {
            // Frequency badge
            ZStack {
                Circle()
                  .fill(color.opacity(0.15))
                  .frame(width: 52, height: 52)
                Text("\(frequency)")
                  .font(.system(size: 18, weight: .bold))
                  .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(keyword.word)
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(.white)
                    KeywordCategoryBadge(category: keyword.category)
                }
                Text(categoryDescription(keyword.category))
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // More actions
            Menu {
                Button {
                    // View related recordings
                } label: {
                    Label("관련 녹음", systemImage: "mic.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                  .foregroundStyle(.white.opacity(0.3))
                  .font(.system(size: 18))
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
    
    private func categoryDescription(_ category: String) -> String {
        switch category {
        case "family": return "가족 & 관계"
        case "career": return "직업 & 사업"
        case "emotion": return "감정 & 느낌"
        case "challenge": return "어려움 & 도전"
        case "peace": return "평화 & 안식"
        case "growth": return "성장 & 학습"
        default: return "기타"
        }
    }
}

// MARK: - Keyword Category Badge

                private struct KeywordCategoryBadge: View {
    let category: String
    
    private var emoji: String {
        switch category {
        case "family": return "👨‍👩‍👧‍👦"
        case "career": return "💼"
        case "emotion": return "💛"
        case "challenge": return "⚡"
        case "peace": return "🕊"
        case "growth": return "🌱"
        default: return "📌"
        }
    }
    
    var body: some View {
        Text(emoji)
          .font(.system(size: 11))
    }
}

// MARK: - Edit Frequency Sheet

                private struct EditFrequencySheet: View {
    let keyword: CLCValueKeyword
    @Binding var frequency: Int
    let onSave: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(keyword.word)
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundStyle(.white)
                        Spacer()
                        Text(categoryDescription(keyword.category))
                          .font(.system(size: 13))
                          .foregroundStyle(.white.opacity(0.6))
                    }
                }
                
                Section("빈도 수정") {
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            Button {
                                withAnimation {
                                    frequency = max(1, frequency - 1)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                  .font(.system(size: 32))
                                  .foregroundStyle(AppColors.neonCyan)
                            }
                            
                            Text("\(frequency)")
                              .font(.system(size: 48, weight: .bold))
                              .foregroundStyle(AppColors.accent)
                              .frame(width: 100)
                            
                            Button {
                                withAnimation {
                                    frequency += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                  .font(.system(size: 32))
                                  .foregroundStyle(AppColors.neonCyan)
                            }
                        }
                        
                        Slider(value: Binding(
                            get: { Double(frequency) },
                            set: { frequency = Int($0) }
                        ), in: 1...100, step: 1)
                    }
                    .padding(.vertical, 12)
                }
                
                Section {
                    HStack(spacing: 4) {
                        Text("현재 빈도:")
                          .foregroundStyle(.white.opacity(0.6))
                        Text("\(frequency)회")
                          .foregroundStyle(AppColors.accent)
                          .fontWeight(.bold)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .foregroundColor(.white)
            .navigationTitle("빈도 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("취소")
                          .foregroundStyle(.white.opacity(0.7))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        onSave(frequency)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
                }
            }
        }
    }
    
    private func categoryDescription(_ category: String) -> String {
        switch category {
        case "family": return "가족 & 관계"
        case "career": return "직업 & 사업"
        case "emotion": return "감정 & 느낌"
        case "challenge": return "어려움 & 도전"
        case "peace": return "평화 & 안식"
        case "growth": return "성장 & 학습"
        default: return "기타"
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
