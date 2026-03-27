import Foundation

struct AppNotification: Identifiable, Codable {
    let id: UUID
    var title: String
    var message: String
    var date: Date
    var isRead: Bool

    init(title: String, message: String) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.date = Date()
        self.isRead = false
    }
}
