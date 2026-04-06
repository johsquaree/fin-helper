import Foundation
import SwiftUI

// Ana uygulama verilerini yöneten ViewModel
class MainViewModel: ObservableObject {
    @Published var currentUser: User
    @Published var groups: [Group] = []
    @Published var selectedGroup: Group?
    @Published var expenses: [Expense] = []
    @Published var personalExpenses: [Expense] = []
    @Published var budgets: [Budget] = []
    @Published var notifications: [AppNotification] = []
    @Published var isSyncing = false

    private let network = NetworkManager.shared
    
    var totalExpenses: Double? {
        guard !expenses.isEmpty else { return nil }
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    init() {
        // Kullanıcı bilgisini UserDefaults'tan al
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        } else {
            self.currentUser = User.emptyUser()
        }
        
        // Kullanıcının harcamalarını yükle
        loadExpenses()
        loadGroups()
        loadPersonalExpenses()
        loadBudgets()
        loadNotifications()
        
        // Uygulama ilk açıldığında selectedGroup'u sıfırla
        selectedGroup = nil
    }
    
    // MARK: - Expense Operations
    
    private func loadExpenses() {
        // UserDefaults'tan kullanıcıya ait harcamaları yükle
        if let expensesData = UserDefaults.standard.data(forKey: "expenses_\(currentUser.id)"),
           let loadedExpenses = try? JSONDecoder().decode([Expense].self, from: expensesData) {
            self.expenses = loadedExpenses
        }
    }
    
    private func saveExpenses() {
        // Kullanıcıya ait harcamaları UserDefaults'a kaydet
        if let expensesData = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(expensesData, forKey: "expenses_\(currentUser.id)")
        }
    }
    
    func addExpense(title: String, amount: Double, category: ExpenseCategory, date: Date = Date(), customEmoji: String? = nil, photoData: Data? = nil) {
        let expense = Expense(
            title: title,
            amount: amount,
            date: date,
            category: category,
            userId: currentUser.id,
            customEmoji: customEmoji,
            photoData: photoData
        )
        expenses.append(expense)
        personalExpenses.append(expense)
        saveExpenses()
        savePersonalExpenses()
        checkBudgetAlert(for: category)
        Task { await syncExpenseToBackend(expense) }
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        personalExpenses.removeAll { $0.id == expense.id }
        saveExpenses()
        savePersonalExpenses()
        Task { await deleteExpenseFromBackend(expense) }
    }

    private func checkBudgetAlert(for category: ExpenseCategory) {
        guard let budget = budgets.first(where: { $0.category == category }) else { return }
        let spent = spentThisMonth(for: category)
        let ratio = spent / budget.monthlyLimit
        if ratio >= 1.0 {
            addNotification(
                title: "\(category.icon) Bütçe Aşıldı",
                message: "\(category.displayName) kategorisinde aylık limitinizi (\(budget.monthlyLimit.formatAsTurkishCurrency())) aştınız."
            )
        } else if ratio >= 0.8 {
            let percent = Int(ratio * 100)
            addNotification(
                title: "\(category.icon) Bütçe Uyarısı",
                message: "\(category.displayName) kategorisinde limitinizin %\(percent)'ini kullandınız."
            )
        }
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            if let personalIndex = personalExpenses.firstIndex(where: { $0.id == expense.id }) {
                personalExpenses[personalIndex] = expense
            }
            saveExpenses()
            savePersonalExpenses()
            Task { await updateExpenseOnBackend(expense) }
        }
    }
    
    // MARK: - Group Operations
    
    private func loadGroups() {
        // UserDefaults'tan kullanıcıya ait grupları yükle
        if let groupsData = UserDefaults.standard.data(forKey: "groups_\(currentUser.id)"),
           let loadedGroups = try? JSONDecoder().decode([Group].self, from: groupsData) {
            self.groups = loadedGroups
        }
    }
    
    func saveGroups() {
        // Kullanıcıya ait grupları UserDefaults'a kaydet
        if let groupsData = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(groupsData, forKey: "groups_\(currentUser.id)")
        }
    }
    
    func createGroup(name: String, members: [String], icon: String) {
        let newGroup = Group(
            name: name,
            members: members,
            expenses: [],
            date: Date(),
            icon: icon
        )
        groups.append(newGroup)
        saveGroups()
    }
    
    func addExpense(to group: Group, title: String, amount: Double, paidBy: String, splitBetween: [String], category: ExpenseCategory, customEmoji: String? = nil, photoData: Data? = nil) {
        let expense = Expense(
            title: title,
            amount: amount,
            date: Date(),
            category: category,
            paidBy: paidBy,
            splitBetween: splitBetween,
            userId: currentUser.id,
            customEmoji: customEmoji,
            photoData: photoData
        )
        
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].expenses.append(expense)
            saveGroups()
        }
    }
    
    func updateGroupExpense(groupId: UUID, expense: Expense) {
        if let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
           let expenseIndex = groups[groupIndex].expenses.firstIndex(where: { $0.id == expense.id }) {
            groups[groupIndex].expenses[expenseIndex] = expense
            saveGroups()
        }
    }
    
    func deleteGroupExpense(groupId: UUID, expenseId: UUID) {
        if let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].expenses.removeAll { $0.id == expenseId }
            saveGroups()
        }
    }
    
    func deleteGroups(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
        saveGroups()
    }

    func deleteGroup(_ group: Group) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }
    
    // Grup güncelleme fonksiyonu
    func updateGroup(_ updatedGroup: Group) {
        if let index = groups.firstIndex(where: { $0.id == updatedGroup.id }) {
            groups[index] = updatedGroup
            saveGroups()
        }
    }
    
    func joinGroup(inviteCode: String) async throws {
        let _ = try await NetworkManager.shared.joinGroupByInviteCode(inviteCode)
        await MainActor.run { loadGroups() }
    }

    // MARK: - User Operations
    
    func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "expenses_\(currentUser.id)")
        UserDefaults.standard.removeObject(forKey: "groups_\(currentUser.id)")
        UserDefaults.standard.removeObject(forKey: "personalExpenses_\(currentUser.id)")
        UserDefaults.standard.removeObject(forKey: "budgets_\(currentUser.id)")
        UserDefaults.standard.removeObject(forKey: "notifications_\(currentUser.id)")
        expenses = []
        groups = []
        personalExpenses = []
        budgets = []
        notifications = []
    }
    
    // Kişisel harcama ekleme
    func addPersonalExpense(title: String, amount: Double, category: ExpenseCategory) {
        let expense = Expense(
            title: title,
            amount: amount,
            date: Date(),
            category: category,
            userId: currentUser.id
        )
        personalExpenses.append(expense)
        savePersonalExpenses()
    }
    
    // Kişisel harcama silme
    func deletePersonalExpense(_ expense: Expense) {
        personalExpenses.removeAll { $0.id == expense.id }
        savePersonalExpenses()
    }
    
    // Kişisel harcamaları kaydetme
    private func savePersonalExpenses() {
        if let encoded = try? JSONEncoder().encode(personalExpenses) {
            UserDefaults.standard.set(encoded, forKey: "personalExpenses_\(currentUser.id)")
        }
    }
    
    // Kişisel harcamaları yükleme
    private func loadPersonalExpenses() {
        if let data = UserDefaults.standard.data(forKey: "personalExpenses_\(currentUser.id)"),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            personalExpenses = decoded
        }
    }

    // MARK: - Budget Operations

    func addBudget(category: ExpenseCategory, monthlyLimit: Double) {
        let budget = Budget(category: category, monthlyLimit: monthlyLimit)
        budgets.append(budget)
        saveBudgets()
    }

    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }

    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
        }
    }

    func spentThisMonth(for category: ExpenseCategory) -> Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses
            .filter { $0.category == category && calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private func saveBudgets() {
        if let encoded = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(encoded, forKey: "budgets_\(currentUser.id)")
        }
    }

    private func loadBudgets() {
        if let data = UserDefaults.standard.data(forKey: "budgets_\(currentUser.id)"),
           let decoded = try? JSONDecoder().decode([Budget].self, from: data) {
            budgets = decoded
        }
    }

    // MARK: - Notification Operations

    func addNotification(title: String, message: String) {
        let notif = AppNotification(title: title, message: message)
        notifications.insert(notif, at: 0)
        saveNotifications()
    }

    func markNotificationRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }

    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
    }

    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        saveNotifications()
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: "notifications_\(currentUser.id)")
        }
    }

    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: "notifications_\(currentUser.id)"),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notifications = decoded
        }
    }

    // MARK: - Backend Sync

    func syncExpensesFromBackend() async {
        await MainActor.run { isSyncing = true }
        defer { Task { await MainActor.run { self.isSyncing = false } } }
        do {
            struct BackendExpense: Decodable {
                let localId: String?
                let _id: String
                let title: String
                let amount: Double
                let date: String
                let category: String?
                let status: String?
            }
            struct ExpenseListResponse: Decodable {
                let expenses: [BackendExpense]
            }
            let response: ExpenseListResponse = try await network.makeRequest(
                endpoint: "/api/expenses?type=personal&limit=200"
            )
            // MongoDB milisaniyeli ISO8601 ("2024-01-15T10:30:00.000Z") için iki formatter
            let isoMs = ISO8601DateFormatter()
            isoMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let isoBasic = ISO8601DateFormatter()

            func parseDate(_ str: String) -> Date {
                isoMs.date(from: str) ?? isoBasic.date(from: str) ?? Date()
            }

            await MainActor.run {
                var changed = false
                for be in response.expenses {
                    guard be.status != "deleted" else { continue }
                    let localId = be.localId ?? be._id
                    guard !expenses.contains(where: { $0.id.uuidString == localId }) else { continue }
                    let cat = ExpenseCategory(rawValue: be.category ?? "") ?? .other
                    let exp = Expense(title: be.title, amount: be.amount,
                                     date: parseDate(be.date),
                                     category: cat, userId: currentUser.id)
                    expenses.append(exp)
                    personalExpenses.append(exp)
                    changed = true
                }
                if changed { saveExpenses(); savePersonalExpenses() }
            }
        } catch { /* çevrimdışıysa sessizce geç */ }
    }

    private func syncExpenseToBackend(_ expense: Expense) async {
        struct CreateBody: Encodable {
            let title: String
            let amount: Double
            let date: String
            let category: String
            let localId: String
            let type: String
        }
        struct AnyResponse: Decodable {}
        let iso = ISO8601DateFormatter()
        let body = CreateBody(
            title: expense.title,
            amount: expense.amount,
            date: iso.string(from: expense.date),
            category: expense.category.rawValue,
            localId: expense.id.uuidString,
            type: "personal"
        )
        guard let data = try? JSONEncoder().encode(body) else { return }
        _ = try? await network.makeRequest(
            endpoint: "/api/expenses", method: .post, body: data
        ) as AnyResponse
    }

    private func updateExpenseOnBackend(_ expense: Expense) async {
        struct UpdateBody: Encodable {
            let title: String
            let amount: Double
            let category: String
        }
        struct AnyResponse: Decodable {}
        let body = UpdateBody(title: expense.title, amount: expense.amount, category: expense.category.rawValue)
        guard let data = try? JSONEncoder().encode(body) else { return }
        _ = try? await network.makeRequest(
            endpoint: "/api/expenses/by-local/\(expense.id.uuidString)", method: .put, body: data
        ) as AnyResponse
    }

    private func deleteExpenseFromBackend(_ expense: Expense) async {
        struct MsgResponse: Decodable { let message: String? }
        _ = try? await network.makeRequest(
            endpoint: "/api/expenses/by-local/\(expense.id.uuidString)", method: .delete
        ) as MsgResponse
    }
}
