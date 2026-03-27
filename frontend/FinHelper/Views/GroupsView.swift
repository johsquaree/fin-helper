import SwiftUI

// MARK: - Groups List
struct GroupsView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingCreateGroup = false

    var body: some View {
        NavigationView {
            SwiftUI.Group {
                if viewModel.groups.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Henüz grup yok")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.groups) { group in
                            NavigationLink(destination: GroupDetailView(group: group, viewModel: viewModel)) {
                                GroupRow(group: group)
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deleteGroups(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { }
                }
            }
            .navigationTitle("Gruplar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingCreateGroup = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Group Row
struct GroupRow: View {
    let group: Group

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 46, height: 46)
                Text(group.icon)
                    .font(.system(size: 24))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("\(group.members.count) kişi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(group.totalExpenses.formatAsTurkishCurrency())
                .font(.body)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Group Detail
struct GroupDetailView: View {
    @State var group: Group
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedTab = 0
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var selectedPerson: String?
    @State private var showingEditGroup = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Harcamalar").tag(0)
                Text("Bakiyeler").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if selectedTab == 0 {
                expensesTab
            } else {
                balancesTab
            }
        }
        .navigationTitle("\(group.icon) \(group.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button { showingAddExpense = true } label: {
                        Image(systemName: "plus")
                    }
                    Menu {
                        Button { showingEditGroup = true } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Grubu Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            GroupAddExpenseView(viewModel: viewModel, group: group)
        }
        .sheet(isPresented: $showingEditGroup) {
            EditGroupView(group: $group, viewModel: viewModel)
        }
        .sheet(item: $selectedExpense) { expense in
            GroupExpenseDetailView(
                expense: expense,
                group: group,
                viewModel: viewModel,
                onDismiss: { selectedExpense = nil }
            )
        }
        .sheet(item: Binding<PersonWrapper?>(
            get: { selectedPerson.map(PersonWrapper.init) },
            set: { _ in selectedPerson = nil }
        )) { wrapper in
            PersonDebtDetailView(person: wrapper.name, group: group, viewModel: viewModel)
        }
        .confirmationDialog("Grubu silmek istediğine emin misin?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                viewModel.deleteGroup(group)
                dismiss()
            }
        }
        .onReceive(viewModel.$groups) { groups in
            if let updated = groups.first(where: { $0.id == group.id }) {
                group = updated
            }
        }
    }

    private var expensesTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SummaryCard(title: "Harcamalarım", amount: myExpenses)
                SummaryCard(title: "Toplam", amount: group.totalExpenses)
            }
            .padding()

            if group.expenses.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Henüz harcama yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(group.expenses) { expense in
                        Button { selectedExpense = expense } label: {
                            GroupExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.deleteGroupExpense(groupId: group.id, expenseId: group.expenses[$0].id) }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var balancesTab: some View {
        let debts = group.calculateDebts()
        return List {
            ForEach(group.members, id: \.self) { member in
                let debt = debts[member] ?? 0
                Button { selectedPerson = member } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(member).font(.body).fontWeight(.medium)
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
                            Text(debt < 0 ? "Borçlu" : debt > 0 ? "Alacaklı" : "Eşit")
                                .font(.caption)
                                .foregroundColor(debt < 0 ? .red : debt > 0 ? .green : .secondary)
                        }
                        Spacer()
                        Text(abs(debt).formatAsTurkishCurrency())
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(debt < 0 ? .red : debt > 0 ? .green : .primary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private var myExpenses: Double {
        group.expenses
            .filter { $0.paidBy == viewModel.currentUser.name && $0.title != "Borç Ödemesi" }
            .reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Edit Group
struct EditGroupView: View {
    @Binding var group: Group
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedIcon: String
    @State private var members: [String]
    @State private var memberInput = ""
    let icons = ["🏠", "✈️", "🍽️", "🎉", "🚗", "💼", "🏖️", "🎮", "🎭", "⚽️", "🛒", "💪"]

    init(group: Binding<Group>, viewModel: MainViewModel) {
        _group = group
        self.viewModel = viewModel
        _name = State(initialValue: group.wrappedValue.name)
        _selectedIcon = State(initialValue: group.wrappedValue.icon)
        _members = State(initialValue: group.wrappedValue.members)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grup Adı")) {
                    TextField("Grup adı", text: $name)
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
                    ForEach(members, id: \.self) { member in
                        HStack {
                            Image(systemName: "person.circle.fill").foregroundColor(.blue)
                            Text(member)
                        }
                    }
                    .onDelete { indexSet in
                        // İlk üye (oluşturucu) silinemez
                        let safe = IndexSet(indexSet.filter { $0 > 0 })
                        members.remove(atOffsets: safe)
                    }
                }

                Section(header: Text("İkon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button { selectedIcon = icon } label: {
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
            .navigationTitle("Grubu Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addMember() {
        let trimmed = memberInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !members.contains(trimmed) else {
            memberInput = ""
            return
        }
        members.append(trimmed)
        memberInput = ""
    }

    private func saveChanges() {
        var updated = group
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.icon = selectedIcon
        updated.members = members.isEmpty ? group.members : members
        viewModel.updateGroup(updated)
        group = updated
        dismiss()
    }
}

// MARK: - Group Expense Row
struct GroupExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 46, height: 46)
                Text(expense.category.icon)
                    .font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.medium)
                if let paidBy = expense.paidBy {
                    Text("\(paidBy) ödedi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(expense.amount.formatAsTurkishCurrency())
                .font(.body)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Group Expense Detail / Edit
struct GroupExpenseDetailView: View {
    let expense: Expense
    let group: Group
    @ObservedObject var viewModel: MainViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory
    @State private var paidBy: String
    @State private var splitEqually: Bool
    @State private var selectedMembers: Set<String>
    @State private var showDeleteConfirm = false

    init(expense: Expense, group: Group, viewModel: MainViewModel, onDismiss: @escaping () -> Void) {
        self.expense = expense
        self.group = group
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        _title = State(initialValue: expense.title)
        _amount = State(initialValue: expense.amount.toTurkishCurrencyInput())
        _selectedCategory = State(initialValue: expense.category)
        _paidBy = State(initialValue: expense.paidBy ?? "")
        _splitEqually = State(initialValue: expense.splitBetween == nil || expense.splitBetween == group.members)
        _selectedMembers = State(initialValue: Set(expense.splitBetween ?? group.members))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Harcama Bilgileri")) {
                    TextField("Başlık", text: $title)

                    HStack {
                        Text("₺").foregroundColor(.secondary)
                        TextField("0,00", text: $amount)
                            .keyboardType(.decimalPad)
                    }

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
                                Text(member).foregroundColor(.primary)
                                Spacer()
                                if paidBy == member {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
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
                                    if selectedMembers.contains(member) {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Harcamayı Sil", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Harcamayı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Harcamayı silmek istediğine emin misin?",
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Sil", role: .destructive) {
                    viewModel.deleteGroupExpense(groupId: group.id, expenseId: expense.id)
                    dismiss()
                    onDismiss()
                }
            }
        }
    }

    private func saveChanges() {
        guard let amountValue = amount.turkishCurrencyToDouble() else { return }
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespaces)
        updated.amount = amountValue
        updated.category = selectedCategory
        updated.paidBy = paidBy
        updated.splitBetween = splitEqually ? group.members : Array(selectedMembers)
        viewModel.updateGroupExpense(groupId: group.id, expense: updated)
        dismiss()
        onDismiss()
    }
}

// MARK: - Helpers

struct PersonWrapper: Identifiable {
    let id = UUID()
    let name: String
}

struct SummaryCard: View {
    let title: String
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(amount.formatAsTurkishCurrency())
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(10)
    }
}
