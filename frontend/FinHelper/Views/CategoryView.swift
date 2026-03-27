import SwiftUI

struct CategoryView: View {
    @ObservedObject var viewModel: MainViewModel

    private var categoryStats: [(category: ExpenseCategory, total: Double, count: Int)] {
        ExpenseCategory.allCases.map { cat in
            let catExpenses = viewModel.expenses.filter { $0.category == cat }
            return (category: cat, total: catExpenses.reduce(0) { $0 + $1.amount }, count: catExpenses.count)
        }
        .filter { $0.count > 0 }
        .sorted { $0.total > $1.total }
    }

    private var grandTotal: Double {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List {
            if categoryStats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Henüz harcama yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(categoryStats, id: \.category) { stat in
                    VStack(spacing: 8) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(uiColor: .systemGray5))
                                    .frame(width: 46, height: 46)
                                Text(stat.category.icon)
                                    .font(.system(size: 22))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.category.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("\(stat.count) harcama")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(stat.total.formatAsTurkishCurrency())
                                    .font(.body)
                                    .fontWeight(.semibold)
                                if grandTotal > 0 {
                                    Text(String(format: "%.0f%%", stat.total / grandTotal * 100))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        if grandTotal > 0 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(uiColor: .systemGray5))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue)
                                        .frame(width: geo.size.width * min(stat.total / grandTotal, 1.0), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Kategoriler")
        .navigationBarTitleDisplayMode(.inline)
    }
}
