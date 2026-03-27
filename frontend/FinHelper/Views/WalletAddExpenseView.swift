import SwiftUI

struct WalletAddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MainViewModel

    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var date = Date()
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Tutar girişi - büyük ve belirgin
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
                .padding(.vertical, 32)
                .background(Color(uiColor: .systemGroupedBackground))

                Form {
                    Section {
                        TextField("Başlık (örn: Market)", text: $title)
                    }

                    Section(header: Text("Kategori")) {
                        Picker("Kategori", selection: $selectedCategory) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Label(category.displayName, systemImage: category.iconName)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section {
                        DatePicker("Tarih", selection: $date, in: ...Date(), displayedComponents: .date)
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
                        .disabled(!isValid)
                }
            }
            .onAppear { amountFocused = true }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount > 0
    }

    private var parsedAmount: Double {
        let cleaned = amount
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0
    }

    private func addExpense() {
        guard isValid else { return }
        viewModel.addExpense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: parsedAmount,
            category: selectedCategory,
            date: date
        )
        dismiss()
    }
}
