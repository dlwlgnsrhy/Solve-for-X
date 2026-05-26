import SwiftUI
import CoreData

@MainActor

struct HomeDashboardView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var databaseManager = DatabaseManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        quickActionsSection
                        statsSection
                        featureCardsSection
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Legacy Vault")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("안녕하세요")
                  .font(.system(size: 14))
                  .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 8) {
                    Image(systemName: "water")
                      .foregroundStyle(AppColors.accent)
                    Text("Ping 상태: 활성")
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(.white)
                }
            }
            Spacer()
            Button {
            } label: {
                Image(systemName: "bell.badge")
                  .font(.system(size: 20))
                  .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            quickActionButton(icon: "mic.fill", title: "Soul Mining", color: AppColors.accent)
            quickActionButton(icon: "lock.shield.fill", title: "Guardian", color: AppColors.neonPink)
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color) -> some View {
        Button {
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                  .font(.system(size: 24))
                  .foregroundStyle(color)
                Text(title)
                  .font(.system(size: 13, weight: .medium))
                  .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Stats
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            statItem(label: "녹음", value: recordedCount, color: AppColors.accent)
            Divider().foregroundStyle(.white.opacity(0.1))
            statItem(label: "저장소", value: vaultCount, color: .orange)
            Divider().foregroundStyle(.white.opacity(0.1))
            statItem(label: "지키미", value: contactCount, color: .blue)
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var recordedCount: Int {
        do {
            let fetch = CLCVoiceLogEntry.fetchRequest() as! NSFetchRequest<CLCVoiceLogEntry>
            return try databaseManager.mainContext.fetch(fetch).count
        } catch { return 0 }
    }
    
    private var vaultCount: Int {
        do {
            let fetch = CLCVaultRecord.fetchRequest() as! NSFetchRequest<CLCVaultRecord>
            return try databaseManager.mainContext.fetch(fetch).count
        } catch { return 0 }
    }
    
    private var contactCount: Int {
        do {
            let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
            return try databaseManager.mainContext.fetch(fetch).count
        } catch { return 0 }
    }
    
    // MARK: - Feature Cards
    
    private var featureCardsSection: some View {
        VStack(spacing: 12) {
            featureCard(
                icon: "mic.fill",
                title: "Soul-Mining",
                subtitle: "음성으로 인생 이야기를 기록하세요",
                color: AppColors.accent
            )
            featureCard(
                icon: "lock.shield.fill",
                title: "Guardian Protocol",
                subtitle: "귀뚜라미 알고리즘으로 유산을 보호하세요",
                color: AppColors.neonPink
            )
            featureCard(
                icon: "sparkles",
                title: "Legacy Agent",
                subtitle: "당신의 AI 유산이 이야기를 이어갑니다",
                color: AppColors.neonCyan
            )
            featureCard(
                icon: "leaf.fill",
                title: "Value Mapping",
                subtitle: "당신의 가치를 지도로 만들어보세요",
                color: .green
            )
        }
    }
    
    private func featureCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button {
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                  .font(.system(size: 20))
                  .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(.white)
                    Text(subtitle)
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                  .font(.system(size: 14))
                  .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Subviews
    
    private func statItem(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
              .font(.system(size: 22, weight: .bold))
              .foregroundStyle(color)
            Text(label)
              .font(.system(size: 11))
              .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
