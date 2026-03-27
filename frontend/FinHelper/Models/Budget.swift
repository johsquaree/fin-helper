import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    var category: ExpenseCategory
    var monthlyLimit: Double

    init(category: ExpenseCategory, monthlyLimit: Double) {
        self.id = UUID()
        self.category = category
        self.monthlyLimit = monthlyLimit
    }
}
