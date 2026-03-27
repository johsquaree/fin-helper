import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory? = nil
    @State private var sortNewest = true

    private var filteredExpenses: [Expense] {
        let filtered = viewModel.expenses.filter { expense in
            let matchesSearch = searchText.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || expense.category == selectedCategory
            return matchesSearch && matchesCategory
        }
        return filtered.sorted { a, b in sortNewest ? a.date > b.date : a.date < b.date }
    }

    private var groupedExpenses: [(String, [Expense])] {
        let calendar = Calendar.current
        let now = Date()
        var groups: [(String, [Expense])] = []
        var grouped: [String: [Expense]] = [:]
        var order: [String] = []

        for expense in filteredExpenses {
            let key: String
            if calendar.isDateInToday(expense.date) {
                key = "Bugün"
            } else if calendar.isDateInYesterday(expense.date) {
                key = "Dün"
            } else if let diff = calendar.dateComponents([.day], from: expense.date, to: now).day, diff < 7 {
                key = "Bu Hafta"
            } else if calendar.isDate(expense.date, equalTo: now, toGranularity: .month) {
                key = "Bu Ay"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                formatter.locale = Locale(identifier: "tr_TR")
                key = formatter.string(from: expense.date).capitalized
            }
            if grouped[key] == nil {
                order.append(key)
                grouped[key] = []
            }
            grouped[key]?.append(expense)
        }
        for key in order {
            if let items = grouped[key] { groups.append((key, items)) }
        }
        return groups
    }

    private var filteredTotal: Double { filteredExpenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toplam
                VStack(spacing: 4) {
                    Text(selectedCategory == nil && searchText.isEmpty ? "Toplam Harcama" : "Filtreli Toplam")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Text(filteredTotal.formatAsTurkishCurrency())
                            .font(.system(size: 40, weight: .bold))
                        if viewModel.isSyncing {
                            ProgressView().scaleEffect(0.7)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(uiColor: .systemGroupedBackground))

                // Kategori filtresi
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "Tümü", icon: nil, isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            FilterChip(title: cat.displayName, icon: cat.icon,
                                       isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                if filteredExpenses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: viewModel.expenses.isEmpty ? "creditcard" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(viewModel.expenses.isEmpty ? "Henüz harcama yok" : "Sonuç bulunamadı")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedExpenses, id: \.0) { sectionTitle, sectionExpenses in
                            Section(header: sectionHeader(sectionTitle, total: sectionExpenses.reduce(0) { $0 + $1.amount })) {
                                ForEach(sectionExpenses) { expense in
                                    Button { selectedExpense = expense } label: {
                                        ExpenseRow(expense: expense)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { indexSet in
                                    let toDelete = indexSet.map { sectionExpenses[$0] }
                                    toDelete.forEach { viewModel.deleteExpense($0) }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.syncExpensesFromBackend()
                    }
                }
            }
            .navigationTitle("Cüzdan")
            .searchable(text: $searchText, prompt: "Harcama ara...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        sortNewest.toggle()
                    } label: {
                        Image(systemName: sortNewest ? "arrow.down.circle" : "arrow.up.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddExpense = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                WalletAddExpenseView(viewModel: viewModel)
            }
            .sheet(item: $selectedExpense) { expense in
                ExpenseDetailView(expense: expense, viewModel: viewModel) {
                    selectedExpense = nil
                }
            }
        }
    }

    private func sectionHeader(_ title: String, total: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
            Text(total.formatAsTurkishCurrency())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon { Text(icon).font(.caption) }
                Text(title).font(.caption).fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(uiColor: .systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Expense Row
struct ExpenseRow: View {
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
                Text(expense.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.formatAsTurkishCurrency())
                    .font(.body)
                    .fontWeight(.semibold)
                Text(expense.shortDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Expense Detail / Edit
struct ExpenseDetailView: View {
    let expense: Expense
    @ObservedObject var viewModel: MainViewModel
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory
    @State private var showDeleteConfirm = false

    init(expense: Expense, viewModel: MainViewModel, onDismiss: @escaping () -> Void) {
        self.expense = expense
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        _title = State(initialValue: expense.title)
        _selectedCategory = State(initialValue: expense.category)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        _amount = State(initialValue: formatter.string(from: NSNumber(value: expense.amount)) ?? "0,00")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Harcama Bilgileri")) {
                    TextField("Başlık", text: $title)
                    HStack {
                        Text("₺").foregroundColor(.secondary)
                        TextField("0,00", text: $amount).keyboardType(.decimalPad)
                    }
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Harcamayı Sil", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Düzenle")
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
                    viewModel.deleteExpense(expense)
                    dismiss()
                    onDismiss()
                }
            }
        }
    }

    private var parsedAmount: Double {
        let cleaned = amount.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? expense.amount
    }

    private func saveChanges() {
        var updated = expense
        updated.title = title.trimmingCharacters(in: .whitespaces)
        updated.amount = parsedAmount
        updated.category = selectedCategory
        viewModel.updateExpense(updated)
        dismiss()
        onDismiss()
    }
}
