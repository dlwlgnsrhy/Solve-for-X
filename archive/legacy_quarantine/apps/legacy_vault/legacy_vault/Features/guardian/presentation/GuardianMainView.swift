import SwiftUI
import CoreData

@MainActor

struct GuardianMainView: View {
    @StateObject private var deadManService = DeadManSwitchService.shared
    @StateObject private var backupService = iCloudBackupService.shared
    @State private var showDeadManSetup: Bool = false
    @State private var showHeirManager: Bool = false
    @State private var showBackupStatus: Bool = false
    @State private var showVaultDecryption: Bool = false
    
    var contactCount: Int {
        do {
            let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
            return try DatabaseManager.shared.mainContext.fetch(fetch).count
        } catch { return 0 }
    }
    
    var activeVaultCount: Int {
        do {
            let fetch = CLCVaultRecord.fetchRequest() as! NSFetchRequest<CLCVaultRecord>
            fetch.predicate = NSPredicate(format: "status == %@", "active")
            return try DatabaseManager.shared.mainContext.fetch(fetch).count
        } catch { return 0 }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        quickStatsSection
                        guardActionsSection
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Guardian Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showDeadManSetup.toggle()
                    } label: {
                        Image(systemName: "plus")
                          .font(.system(size: 18))
                          .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showDeadManSetup) {
                GuardianDeadManView()
            }
            .sheet(isPresented: $showHeirManager) {
                HeirManagerView()
            }
            .sheet(isPresented: $showBackupStatus) {
                BackupStatusView()
            }
            .sheet(isPresented: $showVaultDecryption) {
                VaultDecryptionView()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        Group {
            if deadManService.isConfigured {
                configuredHeader
            } else {
                unconfiguredHeader
            }
        }
    }
    
    private var configuredHeader: some View {
        VStack(spacing: 8) {
            statusBadge
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining")
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.5))
                    Text("\(deadManService.remainingDays) days")
                      .font(.system(size: 28, weight: .bold))
                      .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if deadManService.status == .triggered {
                        Text("TRIGGERED")
                          .font(.system(size: 13, weight: .semibold))
                          .foregroundStyle(AppColors.danger)
                        Text("Heirs notified")
                          .font(.system(size: 11))
                          .foregroundStyle(.white.opacity(0.5))
                    } else {
                        Text("STATUS")
                          .font(.system(size: 11))
                          .foregroundStyle(.white.opacity(0.5))
                        Text(deadManService.status.rawValue.uppercased())
                          .font(.system(size: 12, weight: .medium))
                          .foregroundStyle(deadManService.status.color)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var unconfiguredHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.fill")
              .font(.system(size: 48))
              .foregroundStyle(AppColors.accent.opacity(0.5))
            Text("Dead Man Switch")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(.white)
            Text("Configure your Guardian Protocol")
              .font(.system(size: 13))
              .foregroundStyle(.white.opacity(0.5))
              .multilineTextAlignment(.center)
            Button("Setup Guardian Protocol") {
                showDeadManSetup.toggle()
            }
            .buttonStyle(VaultButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(24)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
              .fill(deadManService.status.color.opacity(0.3))
              .frame(width: 8, height: 8)
            Text(deadManService.status.displayText)
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(deadManService.status.color)
            
            if deadManService.status == .alert {
                Text("•")
                  .foregroundStyle(.white.opacity(0.3))
                Text("Ping soon")
                  .font(.system(size: 11))
                  .foregroundStyle(AppColors.warning.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(deadManService.status.color.opacity(0.08), in: Capsule())
    }
    
    // MARK: - Quick Stats
    
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            miniStat(value: "\(activeVaultCount)", label: "Active Vaults", color: AppColors.accent, icon: "lock.fill")
            Divider().foregroundStyle(.white.opacity(0.08))
            miniStat(value: "\(contactCount)", label: "Guardians", color: AppColors.neonPink, icon: "person.2.fill")
            Divider().foregroundStyle(.white.opacity(0.08))
            miniStat(value: backupService.isAvailable ? "Ready" : "N/A", label: "iCloud", color: AppColors.neonCyan, icon: "cloud.fill")
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func miniStat(value: String, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
              .font(.system(size: 13))
              .foregroundStyle(color.opacity(0.7))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                  .font(.system(size: 15, weight: .semibold))
                  .foregroundStyle(.white)
                Text(label)
                  .font(.system(size: 10))
                  .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var guardActionsSection: some View {
        VStack(spacing: 10) {
            guardActionCard(
                icon: "timer",
                title: "Dead Man Switch",
                subtitle: deadManService.isConfigured ? "\(deadManService.remainingDays) days left" : "Not configured",
                color: AppColors.neonPink,
                action: { showDeadManSetup.toggle() }
            )
            
            guardActionCard(
                icon: "person.3.fill",
                title: "Heir Management",
                subtitle: "\(contactCount) guardians configured",
                color: AppColors.neonCyan,
                action: { showHeirManager.toggle() }
            )
            
            guardActionCard(
                icon: "cloud.badge.checkmark",
                title: "Backup Status",
                subtitle: backupService.backupStatus,
                color: AppColors.accent,
                action: { showBackupStatus.toggle() }
            )
            
            guardActionCard(
                icon: "lock.fill",
                title: "Vault Decryption",
                subtitle: "\(activeVaultCount) vaults decrypted",
                color: .orange,
                action: { showVaultDecryption.toggle() }
            )
        }
    }
    
    private func guardActionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                  .font(.system(size: 20))
                  .foregroundStyle(color)
                  .frame(width: 44, height: 44)
                  .background(color.opacity(0.1), in: Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(.white)
                    Text(subtitle)
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                  .font(.system(size: 13))
                  .foregroundStyle(.white.opacity(0.25))
            }
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Status Color + Display Utilities

extension DeadManSwitchService.DeadManStatus {
    var displayText: String {
        switch self {
        case .idle: return "Idle"
        case .waiting: return "Active"
        case .alert: return "Alert"
        case .triggered: return "Triggered"
        case .disabled: return "Disabled"
        }
    }
    
    var color: Color {
        switch self {
        case .idle, .waiting: return AppColors.accent
        case .alert: return AppColors.warning
        case .triggered: return AppColors.danger
        case .disabled: return .white.opacity(0.35)
        }
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
