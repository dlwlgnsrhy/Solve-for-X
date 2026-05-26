import SwiftUI
import CoreData

@MainActor

struct VaultDecryptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vaults: [CLCVaultRecord] = []
    @State private var decryptingId: String?
    @State private var showExportSheet: Bool = false
    @State private var exportVault: CLCVaultRecord?
    
    private let vaultTypeIcons: [String: String] = [
        "passwords": "key.fill",
        "legal": "doc.fill",
        "financial": "dollarsign.circle.fill",
        "photos": "photo.fill",
        "videos": "film.fill",
        "custom": "folder.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                Group {
                    if vaults.isEmpty {
                        emptyView
                    } else {
                        vaultListView
                    }
                }
            }
            .navigationTitle("Vault Records")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
            }
            .onAppear { loadVaults() }
            .sheet(isPresented: $showExportSheet) {
                if let vault = exportVault {
                    exportView(for: vault)
                }
            }

        }
    }
    
    // MARK: - Data Loading
    
    private func loadVaults() {
        do {
            let fetch = CLCVaultRecord.fetchRequest() as! NSFetchRequest<CLCVaultRecord>
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \CLCVaultRecord.name, ascending: true)]
            vaults = try DatabaseManager.shared.mainContext.fetch(fetch)
        } catch {
        }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.box.fill")
              .font(.system(size: 56))
              .foregroundStyle(AppColors.neonCyan.opacity(0.4))
            
            Text("No Vault Records")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(.white)
            
            Text("Vault records store your encrypted digital assets. They will appear here once created.")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.5))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Vault List
    
    private var vaultListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(vaults, id: \.id) { vault in
                    vaultCard(vault)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Vault Card
    
    private func vaultCard(_ vault: CLCVaultRecord) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: vaultTypeIcon(for: vault.vaultType))
                  .font(.system(size: 24))
                  .foregroundStyle(vaultStatusColor(for: vault.status))
                  .frame(width: 52, height: 52)
                  .background(vaultStatusColor(for: vault.status).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(vault.name ?? "Unnamed Vault")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundStyle(.white)
                        
                        Text(vaultTypeLabel(for: vault.vaultType))
                          .font(.system(size: 10, weight: .medium))
                          .foregroundStyle(.white.opacity(0.5))
                          .padding(.horizontal, 6)
                          .padding(.vertical, 2)
                          .background(.white.opacity(0.08), in: Capsule())
                    }
                    
                    Text("Encrypted")
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                statusBadge(for: vault.status)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Button("View") {
                        decryptVault(vault)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .buttonStyle(.plain)
                    .disabled(decryptingId == vault.id)
                    
                    Spacer()
                    
                    Button("Export") {
                        exportVault = vault
                        showExportSheet = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.neonCyan)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(AppColors.surfaceVariant, in: RoundedRectangle(cornerRadius: 0))
        }
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            Group {
                if decryptingId == vault.id {
                    Color.black.opacity(0.3)
                      .clipShape(RoundedRectangle(cornerRadius: 16))
                    ProgressView()
                      .tint(.white)
                }
            }
        )
    }
    
    // MARK: - Export View
    
    private func exportView(for vault: CLCVaultRecord) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: vaultTypeIcon(for: vault.vaultType))
                          .font(.system(size: 28))
                          .foregroundStyle(AppColors.neonCyan)
                        Text(vault.name ?? "Vault")
                          .font(.system(size: 18, weight: .semibold))
                          .foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        exportDetailRow("Type", value: vaultTypeLabel(for: vault.vaultType))
                        exportDetailRow("Status", value: vault.status.capitalized)
                        exportDetailRow("Encrypted", value: "AES-256-GCM")
                    }
                    .padding(16)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                    
                    Text("Export will decrypt and save your vault data securely.")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.5))
                      .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Export Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
    }
    
    private func exportDetailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
              .font(.system(size: 13))
              .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(.white)
        }
    }
    
    // MARK: - Helpers
    
    private func vaultTypeIcon(for type: String) -> String {
        vaultTypeIcons[type] ?? "lock.fill"
    }
    
    private func vaultTypeLabel(for type: String) -> String {
        switch type {
        case "passwords": return "Passwords"
        case "legal": return "Legal"
        case "financial": return "Financial"
        case "photos": return "Photos"
        case "videos": return "Videos"
        case "custom": return "Custom"
        default: return type.capitalized
        }
    }
    
    private func vaultStatusColor(for status: String) -> Color {
        switch status {
        case "active": return AppColors.accent
        case "paused": return AppColors.warning
        case "expired": return AppColors.danger
        case "alert_sent": return AppColors.neonCyan
        default: return .white.opacity(0.5)
        }
    }
    
    private func statusBadge(for status: String) -> some View {
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(vaultStatusColor(for: status))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(vaultStatusColor(for: status).opacity(0.1), in: Capsule())
    }
    
    // MARK: - Actions
    
    private func decryptVault(_ vault: CLCVaultRecord) {
        decryptingId = vault.id
        defer { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { decryptingId = nil } }
        // In production: use KeychainHelper + EncryptionService to verify decryption capability
    }
}

// Preview disabled for compilation compatibility
