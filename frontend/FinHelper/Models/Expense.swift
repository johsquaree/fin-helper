import Foundation

// Harcama kategorileri
enum ExpenseCategory: String, Codable, CaseIterable {
    case food = "Yemek"
    case transportation = "Ulaşım"
    case accommodation = "Konaklama"
    case health = "Sağlık"
    case shopping = "Alışveriş"
    case entertainment = "Eğlence"
    case bills = "Faturalar"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .food:          return "🍽️"
        case .transportation: return "🚗"
        case .accommodation: return "🏨"
        case .health:        return "💊"
        case .shopping:      return "🛍️"
        case .entertainment: return "🎬"
        case .bills:         return "📄"
        case .other:         return "📦"
        }
    }

    var iconName: String {
        switch self {
        case .food:          return "fork.knife"
        case .transportation: return "car.fill"
        case .accommodation: return "house.fill"
        case .health:        return "heart.fill"
        case .shopping:      return "bag.fill"
        case .entertainment: return "film.fill"
        case .bills:         return "doc.text.fill"
        case .other:         return "square.grid.2x2.fill"
        }
    }

    var displayName: String { rawValue }
}

// Harcama modeli
struct Expense: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Double
    let date: Date
    var category: ExpenseCategory
    var paidBy: String?
    var splitBetween: [String]?
    let userId: String
    var customEmoji: String?
    var photoData: Data?
    
    // Formatlı tarih (uzun)
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    // Kısa tarih (d MMM)
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    // Kişi başı düşen miktar (2 ondalık basamağa yuvarlanmış)
    var amountPerPerson: Double {
        guard let split = splitBetween, !split.isEmpty else { 
            return (amount * 100).rounded() / 100 
        }
        let perPerson = amount / Double(split.count)
        return (perPerson * 100).rounded() / 100
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, amount, date, category, paidBy, splitBetween, userId, customEmoji, photoData
    }
    
    // Kişisel harcama için initializer
    init(title: String, amount: Double, date: Date, category: ExpenseCategory, userId: String, customEmoji: String? = nil, photoData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.paidBy = nil
        self.splitBetween = nil
        self.userId = userId
        self.customEmoji = customEmoji
        self.photoData = photoData
    }
    
    // Grup harcaması için initializer
    init(title: String, amount: Double, date: Date, category: ExpenseCategory, paidBy: String, splitBetween: [String], userId: String, customEmoji: String? = nil, photoData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.paidBy = paidBy
        self.splitBetween = splitBetween
        self.userId = userId
        self.customEmoji = customEmoji
        self.photoData = photoData
    }
} 