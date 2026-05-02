import SwiftUI

@MainActor

struct BackupStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupService = iCloudBackupService.shared
    @State private var isRunningBackup: Bool = false
    @State private var backupMessage: String?
    @State private var showBackupMessage: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        iCloudStatusCard
                        backupInfoCard
                        backupActionsCard
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Backup Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
            }
            .alert("Backup Complete", isPresented: $showBackupMessage) {
                Button("OK") {}
            } message: {
                Text(backupMessage ?? "Backup finished")
            }
        }
    }
    
    // MARK: - iCloud Status
    
    private var iCloudStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "cloud.fill")
              .font(.system(size: 32))
              .foregroundStyle(backupService.isAvailable ? AppColors.accent : AppColors.danger)
              .frame(width: 56, height: 56)
              .background(backupService.isAvailable ? AppColors.accent.opacity(0.1) : AppColors.danger.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(backupService.isAvailable ? "iCloud Ready" : "iCloud Unavailable")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.white)
                
                if backupService.isAvailable {
                    Text("CloudKit backup available")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Sign in to iCloud to enable backups")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Image(systemName: backupService.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
              .font(.system(size: 20))
              .foregroundStyle(backupService.isAvailable ? AppColors.accent : AppColors.danger.opacity(0.6))
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Backup Info
    
    private var backupInfoCard: some View {
        VStack(spacing: 14) {
            infoRow(icon: "clock.arrow.circlepath", title: "Last Backup", value: backupService.lastBackupDate.map {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return formatter.string(from: $0)
            } ?? "Never")
            
            infoRow(icon: "lock.fill", title: "Encryption", value: "AES-256-GCM", valueColor: AppColors.accent)
            
            infoRow(icon: "cube.transparent", title: "Backup Size", value: formatSize(backupService.backupSize))
            
            infoRow(icon: "bolt.fill", title: "Backup State", value: backupService.isBackedUp ? "Up to date" : "Needs backup")
              .foregroundStyle(backupService.isBackedUp ? AppColors.accent : AppColors.warning)
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func infoRow(icon: String, title: String, value: String, valueColor: Color = .white.opacity(0.7)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
              .font(.system(size: 16))
              .foregroundStyle(.white.opacity(0.4))
              .frame(width: 24)
            Text(title)
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(valueColor)
        }
    }
    
    // MARK: - Backup Actions
    
    private var backupActionsCard: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await runBackup()
                }
            } label: {
                HStack(spacing: 8) {
                    if isRunningBackup {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text(isRunningBackup ? "Backing up..." : "Back Up Now")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(VaultButtonStyle())
            .disabled(isRunningBackup || !backupService.isAvailable)
            .opacity(!backupService.isAvailable ? 0.4 : 1)
            
            Button {
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Restore from Backup")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.neonCyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.neonCyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!backupService.isAvailable || !backupService.isBackedUp)
            .opacity(!backupService.isAvailable || !backupService.isBackedUp ? 0.3 : 1)
        }
    }
    
    // MARK: - Actions
    
    private func runBackup() async {
        isRunningBackup = true
        defer { isRunningBackup = false }
        
        do {
            try await backupService.runFullBackup()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            backupMessage = "Backup complete at \(formatter.string(from: Date()))"
            showBackupMessage = true
        } catch {
            backupMessage = "Backup failed: \(error.localizedDescription)"
            showBackupMessage = true
        }
    }
    
    private func formatSize(_ bytes: Int) -> String {
        if bytes == 0 { return "0 B" }
        let kilobytes = Double(bytes) / 1024.0
        if kilobytes < 1024 { return String(format: "%.1f KB", kilobytes) }
        let megabytes = kilobytes / 1024.0
        return String(format: "%.1f MB", megabytes)
    }
}

// Preview disabled for compilation compatibility
