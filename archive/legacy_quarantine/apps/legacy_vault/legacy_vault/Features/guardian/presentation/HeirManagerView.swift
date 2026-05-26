import SwiftUI
import CoreData

@MainActor

struct HeirManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddForm: Bool = false
    @State private var showEditForm: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var editingContactId: String = ""
    @State private var editingContactName: String = ""
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var editRelationship: String = "spouse"
    
    private let relationships: [String] = ["spouse", "child", "friend", "organization"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                Group {
                    if fetchContacts().isEmpty {
                        emptyView
                    } else {
                        contactListView
                    }
                }
            }
            .navigationTitle("Guardian Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddForm = true } label: {
                        Image(systemName: "plus")
                          .font(.system(size: 18))
                          .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .alert("Delete Guardian?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    guard !editingContactId.isEmpty else { return }
                    deleteContact(by: editingContactId)
                }
            } message: {
                Text("Remove \"\(editingContactName)\"? This cannot be undone.")
            }

            .sheet(isPresented: $showAddForm) {
                heirFormView(isAdding: true)
            }
            .sheet(isPresented: $showEditForm) {
                heirFormView(isAdding: false)
            }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchContacts() -> [CLCInheritanceContact] {
        do {
            let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
            fetch.sortDescriptors = [NSSortDescriptor(keyPath: \CLCInheritanceContact.name, ascending: true)]
            return try DatabaseManager.shared.mainContext.fetch(fetch)
        } catch { return [] }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
              .font(.system(size: 56))
              .foregroundStyle(AppColors.neonPink.opacity(0.4))
            
            Text("No Guardians Yet")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(.white)
            
            Text("Add trusted contacts who can access your vault if you cannot ping the system.")
              .font(.system(size: 14))
              .foregroundStyle(.white.opacity(0.5))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
            
            Spacer()
            
            Button { showAddForm = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Guardian")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.neonPink)
                .padding(.vertical, 12)
                .frame(maxWidth: 240)
                .background(AppColors.neonPink.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Contact List
    
    private var contactListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(fetchContacts(), id: \.objectID) { contact in
                    heirContactCard(contact)
                }
                
                Button { showAddForm = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Guardian")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.neonPink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.neonPink.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
    }
    
    // MARK: - Contact Card
    
    private func heirContactCard(_ contact: CLCInheritanceContact) -> some View {
        VStack(spacing: 0) {
            Button {
                editingContactId = contact.id
                editingContactName = contact.name
                editName = contact.name
                editEmail = contact.email
                editRelationship = contactRelationshipFromRaw(contact.relationship)
                showEditForm = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: contactRelationshipIcon(contact.relationship))
                      .font(.system(size: 22))
                      .foregroundStyle(AppColors.neonPink)
                      .frame(width: 48, height: 48)
                      .background(AppColors.neonPink.opacity(0.1), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundStyle(.white)
                        Text(contact.email)
                          .font(.system(size: 13))
                          .foregroundStyle(.white.opacity(0.5))
                        Text(contact.relationship.capitalized)
                          .font(.system(size: 11, weight: .medium))
                          .foregroundStyle(AppColors.neonPink.opacity(0.7))
                          .padding(.horizontal, 8)
                          .padding(.vertical, 2)
                          .background(AppColors.neonPink.opacity(0.1), in: Capsule())
                    }
                    
                    Spacer()
                }
                .padding(14)
            }
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
            
            Divider()
                .background(.white.opacity(0.06))
                .padding(.leading, 70)
        }
    }
    
    // MARK: - Form Sheet
    
    @ViewBuilder
    private func heirFormView(isAdding: Bool) -> some View {
        let initialName = isAdding ? "" : editName
        let initialEmail = isAdding ? "" : editEmail
        
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                          .font(.system(size: 13, weight: .medium))
                          .foregroundStyle(.white.opacity(0.7))
                        TextField("e.g. Jane Doe", text: .constant(initialName))
                          .textFieldStyle(VaultTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email or Phone")
                          .font(.system(size: 13, weight: .medium))
                          .foregroundStyle(.white.opacity(0.7))
                        TextField("e.g. jane@example.com", text: .constant(initialEmail))
                          .textFieldStyle(VaultTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Relationship")
                          .font(.system(size: 13, weight: .medium))
                          .foregroundStyle(.white.opacity(0.7))
                        Menu(editRelationship.capitalized) {
                            ForEach(relationships, id: \.self) { rel in
                                Button {
                                    if isAdding {
                                        editRelationship = rel
                                    } else {
                                        editRelationship = rel
                                        editingContactId = ""
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: rel == "spouse" ? "heart.fill" :
                                              rel == "child" ? "person.2.fill" :
                                              rel == "friend" ? "person.badge.plus.fill" :
                                              "building.2.fill")
                                        Text(rel.capitalized)
                                    }
                                    if rel == editRelationship {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                          .foregroundStyle(AppColors.accent)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }
                }
                
                Button(isAdding ? "Add Guardian" : "Save Changes") {
                    if isAdding {
                        addNewContact(editName, editEmail, editRelationship)
                    } else {
                        saveEditedContact(editName, editEmail, editRelationship)
                    }
                    dismiss()
                }
                .buttonStyle(VaultButtonStyle())
                .disabled(isAdding ? initialName.isEmpty || initialEmail.isEmpty : editName.isEmpty || editEmail.isEmpty)
                .padding(.horizontal, 32)
                
                if !isAdding {
                    Button("Delete Guardian", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .buttonStyle(VaultButtonStyle())
                    .padding(.horizontal, 32)
                }
                
                Spacer(minLength: 20)
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    
    private func addNewContact(_ name: String, _ email: String, _ relationship: String) {
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "CLCInheritanceContact",
            into: DatabaseManager.shared.mainContext
        ) as! CLCInheritanceContact
        entity.id = UUID().uuidString
        entity.name = name
        entity.email = email
        entity.relationship = relationship
        entity.notificationStatus = Int16(0)
        
        do { try DatabaseManager.shared.saveContext() }
        catch {}
    }
    
    private func saveEditedContact(_ name: String, _ email: String, _ relationship: String) {
        guard !editingContactId.isEmpty else { return }
        let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
        fetch.predicate = NSPredicate(format: "id == %@", editingContactId)
        
        guard let existing = try? DatabaseManager.shared.mainContext.fetch(fetch).first else { return }
        existing.name = name
        existing.email = email
        existing.relationship = relationship
        
        do { try DatabaseManager.shared.saveContext() }
        catch {}
    }
    
    private func deleteContact(by id: String) {
        let fetch = CLCInheritanceContact.fetchRequest() as! NSFetchRequest<CLCInheritanceContact>
        fetch.predicate = NSPredicate(format: "id == %@", id)
        guard let stored = try? DatabaseManager.shared.mainContext.fetch(fetch).first else { return }
        DatabaseManager.shared.delete(stored)
    }

    private func contactRelationshipIcon(_ raw: String) -> String {
        switch raw {
        case "spouse": return "heart.fill"
        case "child": return "person.2.fill"
        case "friend": return "person.badge.plus.fill"
        case "organization": return "building.2.fill"
        default: return "person.fill"
        }
    }
    
    private func contactRelationshipFromRaw(_ raw: String) -> String {
        ["spouse", "child", "friend", "organization"].contains(raw) ? raw : "spouse"
    }
}

// Preview disabled for compilation compatibility
