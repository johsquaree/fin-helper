import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var selectedIcon = "🏠"
    @State private var memberInput = ""
    @State private var members: [String] = []
    @FocusState private var nameFocused: Bool

    let icons = ["🏠", "✈️", "🍽️", "🎉", "🚗", "💼", "🏖️", "🎮", "🎭", "⚽️", "🛒", "💪"]

    private var allDisplayMembers: [String] {
        ([viewModel.currentUser.name] + members).filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grup Adı")) {
                    TextField("örn: Tatil, Ev Arkadaşları...", text: $groupName)
                        .focused($nameFocused)
                }

                Section(header: Text("Üyeler")) {
                    HStack {
                        TextField("Üye adı ekle...", text: $memberInput)
                            .autocapitalization(.words)
                        Button(action: addMember) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .disabled(memberInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    ForEach(allDisplayMembers, id: \.self) { member in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text(member)
                            if member == viewModel.currentUser.name {
                                Text("Sen")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        // 0. index = kullanıcının kendisi, silinemez
                        let adjustedIndexSet = IndexSet(indexSet.map { $0 - 1 }.filter { $0 >= 0 })
                        members.remove(atOffsets: adjustedIndexSet)
                    }
                }

                Section(header: Text("İkon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Text(icon)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon
                                                  ? Color.blue.opacity(0.15)
                                                  : Color(uiColor: .systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Yeni Grup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") { createGroup() }
                        .fontWeight(.semibold)
                        .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    private func addMember() {
        let trimmed = memberInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed != viewModel.currentUser.name,
              !members.contains(trimmed) else {
            memberInput = ""
            return
        }
        members.append(trimmed)
        memberInput = ""
    }

    private func createGroup() {
        let name = groupName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let allMembers = [viewModel.currentUser.name] + members
        viewModel.createGroup(name: name, members: allMembers, icon: selectedIcon)
        dismiss()
    }
}
