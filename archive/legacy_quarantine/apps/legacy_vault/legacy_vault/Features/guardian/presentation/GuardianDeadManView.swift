import SwiftUI
import CoreData

@MainActor

struct GuardianDeadManView: View {
    @StateObject private var deadManService = DeadManSwitchService.shared
    @State private var isPinging: Bool = false
    @State private var showConfirmPing: Bool = false
    @State private var showNewHeir: Bool = false
    @State private var selectedDeadlineDays: Int = 7
    @State private var isNewHiredName = ""
    @State private var isNewHiredEmail = ""
    @State private var selectedRelationship: String = "spouse"
    @State private var showSetupView: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if deadManService.isConfigured && !showSetupView {
                            countdownSection
                            statusSection
                            pingSection
                        } else {
                            configurationForm
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Guardian Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.accent)
                }
                
                if deadManService.isConfigured && !showSetupView {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Configure") {
                            showSetupView.toggle()
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .confirmationDialog("Confirmation", isPresented: $showConfirmPing, titleVisibility: .visible) {
                Button("Confirm I'm Alive") {
                    confirmPing()
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("Are you alive? This will reset the countdown timer.")
            }
            .alert("Guardian Protocol", isPresented: $showNewHeir) {
                createNewHeirSheet
            } message: {
                Text("Add an heir contact")
            }
            .alert("Save Changes", isPresented: $showSetupView, actions: {
                saveHeirsAndVaults
            }, message: {
                setupFormFields
            })
        }
    }
    
    // MARK: - Countdown Section
    
    private var countdownSection: some View {
        VStack(spacing: 12) {
            Text("Countdown Timer")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(.white.opacity(0.5))
              .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(deadManService.remainingDays)")
                      .font(.system(size: 48, weight: .bold))
                      .foregroundStyle(.white)
                    Text("Days")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        HStack(spacing: 12) {
            Circle()
              .fill(deadManService.status.color.opacity(0.3))
              .frame(width: 12, height: 12)
              .overlay(
                  Circle()
                    .stroke(deadManService.status.color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(deadManService.status == .alert ? 1.0 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: deadManService.status)
              )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(deadManService.status.displayText)
                      .font(.system(size: 15, weight: .semibold))
                      .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(deadManService.contacts.count) guardians")
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.4))
                }
                
                Text("Deadline: \(deadManService.contacts.isEmpty ? "Not set" : "Configured")")
                  .font(.system(size: 12))
                  .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Ping Section
    
    private var pingSection: some View {
        VStack(spacing: 16) {
            if deadManService.status == .triggered {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .font(.system(size: 40))
                      .foregroundStyle(AppColors.danger)
                    
                    Text("Guardian Protocol Triggered")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(.white)
                    
                    Text("Heir contacts have been notified. The dead man switch cannot be reset.")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.5))
                      .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(AppColors.danger.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            } else if deadManService.status == .alert {
                VStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                      .font(.system(size: 36))
                      .foregroundStyle(AppColors.warning)
                      .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false), value: deadManService.status)
                    
                    Text("Ping Required")
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundStyle(AppColors.warning)
                    
                    Text("Your ping is overdue. Confirm you're alive to reset the timer.")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.5))
                      .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(AppColors.warning.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                showConfirmPing = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("I'm Alive")
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(VaultButtonStyle())
            .disabled(isPinging || deadManService.status == .triggered)
            .overlay(
                Group {
                    if isPinging {
                        ProgressView()
                          .tint(.white)
                    }
                }
            )
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - New Heir Sheet
    
    @ViewBuilder
    private var createNewHeirSheet: some View {
        VStack(spacing: 12) {
            TextField("Contact Name", text: $isNewHiredName)
              .padding(14)
              .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
              .foregroundStyle(.white)
            
            TextField("Email or Phone", text: $isNewHiredEmail)
              .keyboardType(.emailAddress)
              .padding(14)
              .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
              .foregroundStyle(.white)
            
            Menu(selectedRelationship.capitalized) {
                ForEach(["spouse", "child", "friend", "organization"], id: \.self) { relStr in
                    Button(relStr.capitalized) {
                        selectedRelationship = relStr
                    }
                }
            }
            .padding(14)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            
            Button("Add Guardian") {
                addHeirContact()
                isNewHiredName = ""
                isNewHiredEmail = ""
                showNewHeir = false
            }
            .buttonStyle(VaultButtonStyle())
            .disabled(isNewHiredName.isEmpty || isNewHiredEmail.isEmpty)
            .padding(.horizontal, 32)
        }
        .padding(20)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Configuration Form
    
    private var configurationForm: some View {
        VStack(spacing: 16) {
            // Heir contacts list
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Guardian Contacts")
                      .font(.system(size: 14, weight: .medium))
                      .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Button("Add", action: { showNewHeir = true })
                      .foregroundStyle(AppColors.neonPink)
                      .font(.system(size: 13, weight: .medium))
                }
                
                if deadManService.contacts.isEmpty {
                    Text("No guardians added yet")
                      .font(.system(size: 13))
                      .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                } else {
                    ForEach(deadManService.contacts, id: \.objectID) { contact in
                        heirContactRow(contact)
                    }
                }
            }
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            
            // Deadline slider
            VStack(spacing: 8) {
                HStack {
                    Text("Ping Deadline")
                      .font(.system(size: 14, weight: .medium))
                      .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(selectedDeadlineDays) days")
                      .font(.system(size: 14, weight: .semibold))
                      .foregroundStyle(AppColors.accent)
                }
                
                Slider(value: Binding(
                    get: { Double(selectedDeadlineDays) },
                    set: { selectedDeadlineDays = Int($0) }
                ), in: 1...90, step: 1)
                  .tint(AppColors.accent)
            }
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            
            // Active vaults check
            VStack(alignment: .leading, spacing: 8) {
                Text("Vaults to Protect")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(.white.opacity(0.7))
                
                ForEach(deadManService.vaults, id: \.objectID) { vault in
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                          .foregroundStyle(AppColors.neonCyan)
                        Text(vault.name ?? "Vault")
                          .font(.system(size: 13))
                          .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                }
                
                if deadManService.vaults.isEmpty {
                    Text("Create a vault entry first")
                      .font(.system(size: 12))
                      .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
            
            Button("Configure Guardian Protocol") {
                showSetupView = true
            }
            .buttonStyle(VaultButtonStyle())
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Heir Contact Row
    
        private func heirContactRow(_ contact: CLCInheritanceContact) -> some View {
        HStack(spacing: 10) {
            Image(systemName: contactRelationshipIcon(contact.relationship))
              .foregroundStyle(AppColors.neonPink)
              .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(.white)
                Text(contact.relationship.capitalized)
                  .font(.system(size: 11))
                  .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            Menu {
                Button("Delete", role: .destructive) {
                    deleteHeirContact(contact)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                  .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(10)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Setup Alert
    @ViewBuilder
    private var saveHeirsAndVaults: some View {
        Button("Save Configuration") {
            saveConfiguration()
            showSetupView = false
        }
        .keyboardShortcut(.defaultAction)
    }
    
    @ViewBuilder
    private var setupFormFields: some View {
        Text("This will configure your dead man switch with \(selectedDeadlineDays) days countdown and \(deadManService.contacts.count) guardian(s).")
    }
    
    // MARK: - Actions
    
    private func addHeirContact() {
        guard !isNewHiredName.isEmpty, !isNewHiredEmail.isEmpty else { return }
        
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "CLCInheritanceContact",
            into: DatabaseManager.shared.mainContext
        ) as! CLCInheritanceContact
        
        entity.id = UUID().uuidString
        entity.name = isNewHiredName
        entity.email = isNewHiredEmail
        entity.relationship = selectedRelationship
        entity.notificationStatus = Int16(0)
        
        do {
            try DatabaseManager.shared.saveContext()
        } catch {}
    }
    
    private func deleteHeirContact(_ contact: CLCInheritanceContact) {
        guard let storedContact = fetchStoredContact(with: contact.id) else { return }
        DatabaseManager.shared.delete(storedContact)
    }
    
    private func confirmPing() {
        isPinging = true
        deadManService.pingAlive()
        
        withAnimation {
            isPinging = false
        }
    }
    
    private func saveConfiguration() {
        deadManService.remainingDays = selectedDeadlineDays
        deadManService.isConfigured = true
        deadManService.status = .waiting
        
        do { try DatabaseManager.shared.saveContext() } catch {}
    }
    
    // MARK: - Helpers
    
    private func fetchStoredContact(with id: String) -> CLCInheritanceContact? {
        let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
        fetch.predicate = NSPredicate(format: "id == %@", id)
        return try? DatabaseManager.shared.mainContext.fetch(fetch).first
    }
    
    private func contactRelationshipIcon(_ relationship: String) -> String {
        switch relationship {
        case "spouse": return "heart.fill"
        case "child": return "person.2.fill"
        case "friend": return "person.badge.plus.fill"
        case "organization": return "building.2.fill"
        default: return "person.fill"
        }
    }
    
    private func contactRelationshipFromRaw(_ raw: String) -> InheritanceContact.Relationship {
        return InheritanceContact.Relationship(rawValue: raw) ?? .spouse
    }
}

// MARK: - Preview

// Preview disabled for compilation compatibility
