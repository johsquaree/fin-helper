import SwiftUI

struct BudgetView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showingAddBudget = false

    var body: some View {
        List {
            if viewModel.budgets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Henüz bütçe yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Kategori başına aylık harcama limiti belirle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.budgets) { budget in
                    BudgetRow(budget: budget, spent: viewModel.spentThisMonth(for: budget.category))
                }
                .onDelete { indexSet in
                    indexSet.forEach { viewModel.deleteBudget(viewModel.budgets[$0]) }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Bütçeler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddBudget = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView(viewModel: viewModel)
        }
    }
}

// MARK: - Budget Row
struct BudgetRow: View {
    let budget: Budget
    let spent: Double

    private var progress: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return min(spent / budget.monthlyLimit, 1.0)
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .red }
        if progress >= 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 46, height: 46)
                    Text(budget.category.icon)
                        .font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.category.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Bu ay")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spent.formatAsTurkishCurrency())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                    Text("/ \(budget.monthlyLimit.formatAsTurkishCurrency())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Budget
struct AddBudgetView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExpenseCategory = .food
    @State private var limitText = ""

    private var availableCategories: [ExpenseCategory] {
        let used = Set(viewModel.budgets.map { $0.category })
        return ExpenseCategory.allCases.filter { !used.contains($0) }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kategori")) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(header: Text("Aylık Limit")) {
                    HStack {
                        Text("₺").foregroundColor(.secondary)
                        TextField("0,00", text: $limitText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Bütçe Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") { addBudget() }
                        .fontWeight(.semibold)
                        .disabled(parsedLimit <= 0 || availableCategories.isEmpty)
                }
            }
            .onAppear {
                if let first = availableCategories.first {
                    selectedCategory = first
                }
            }
        }
    }

    private var parsedLimit: Double {
        let cleaned = limitText
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }

    private func addBudget() {
        guard parsedLimit > 0 else { return }
        viewModel.addBudget(category: selectedCategory, monthlyLimit: parsedLimit)
        dismiss()
    }
}
