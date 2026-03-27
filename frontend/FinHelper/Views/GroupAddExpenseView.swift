import SwiftUI

struct GroupAddExpenseView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    let group: Group

    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var paidBy = ""
    @State private var splitEqually = true
    @State private var selectedMembers: Set<String> = []
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Büyük tutar alanı
                VStack(spacing: 8) {
                    Text("Tutar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .center, spacing: 4) {
                        Text("₺")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.secondary)
                        TextField("0,00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .focused($amountFocused)
                            .frame(maxWidth: 220)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color(uiColor: .systemGroupedBackground))

                Form {
                    Section {
                        TextField("Başlık (örn: Akşam yemeği)", text: $title)

                        Picker("Kategori", selection: $selectedCategory) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section(header: Text("Ödeyen")) {
                        ForEach(group.members, id: \.self) { member in
                            Button { paidBy = member } label: {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue)
                                    Text(member)
                                        .foregroundColor(.primary)
                                    if member == viewModel.currentUser.name {
                                        Text("Sen")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if paidBy == member {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section(header: Text("Bölüşme")) {
                        Picker("", selection: $splitEqually) {
                            Text("Eşit Böl").tag(true)
                            Text("Kişi Seç").tag(false)
                        }
                        .pickerStyle(.segmented)

                        if !splitEqually {
                            ForEach(group.members, id: \.self) { member in
                                Button {
                                    if selectedMembers.contains(member) {
                                        selectedMembers.remove(member)
                                    } else {
                                        selectedMembers.insert(member)
                                    }
                                } label: {
                                    HStack {
                                        Text(member).foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: selectedMembers.contains(member)
                                              ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedMembers.contains(member) ? .blue : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Harcama Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") { addExpense() }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .onAppear {
                amountFocused = true
                if let first = group.members.first {
                    paidBy = viewModel.currentUser.name.isEmpty ? first : viewModel.currentUser.name
                    if !group.members.contains(paidBy) { paidBy = first }
                }
                selectedMembers = Set(group.members)
            }
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedAmount > 0 &&
        !paidBy.isEmpty &&
        (splitEqually || !selectedMembers.isEmpty)
    }

    private var parsedAmount: Double {
        let cleaned = amount
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }

    private func addExpense() {
        guard isFormValid else { return }
        let splitBetween = splitEqually ? group.members : Array(selectedMembers)
        viewModel.addExpense(
            to: group,
            title: title.trimmingCharacters(in: .whitespaces),
            amount: parsedAmount,
            paidBy: paidBy,
            splitBetween: splitBetween,
            category: selectedCategory
        )
        dismiss()
    }
}
