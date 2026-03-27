import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let networkManager = NetworkManager.shared

    init() {
        Task { await checkAuth() }
    }

    func checkAuth() async {
        guard
            let userData = UserDefaults.standard.data(forKey: "currentUser"),
            let savedUser = try? JSONDecoder().decode(User.self, from: userData),
            UserDefaults.standard.string(forKey: "accessToken") != nil
        else { return }

        // Önce kayıtlı kullanıcıyla UI'ı aç, sonra token'ı backend'de doğrula
        self.currentUser = savedUser
        self.isAuthenticated = true

        do {
            struct MeResponse: Decodable {
                let id: String?
                let _id: String?
                let name: String?
                let email: String?
            }
            let _: MeResponse = try await networkManager.makeRequest(endpoint: "/api/auth/me")
        } catch NetworkError.unauthorized {
            // Token geçersiz, çıkış yap
            logout()
        } catch {
            // Çevrimdışı — mevcut session'ı koru
        }
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let body = try JSONEncoder().encode(SignUpRequest(email: email, password: password, name: name))
            let response: AuthResponse = try await networkManager.makeRequest(
                endpoint: "/api/auth/register", method: .post, body: body
            )
            handleAuthSuccess(response)
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Beklenmeyen bir hata oluştu"
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let body = try JSONEncoder().encode(["email": email, "password": password])
            let response: AuthResponse = try await networkManager.makeRequest(
                endpoint: "/api/auth/login", method: .post, body: body
            )
            handleAuthSuccess(response)
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Beklenmeyen bir hata oluştu"
        }

        isLoading = false
    }

    func logout() {
        let userId = currentUser?.id
        networkManager.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        if let id = userId {
            UserDefaults.standard.removeObject(forKey: "expenses_\(id)")
            UserDefaults.standard.removeObject(forKey: "groups_\(id)")
            UserDefaults.standard.removeObject(forKey: "personalExpenses_\(id)")
            UserDefaults.standard.removeObject(forKey: "budgets_\(id)")
            UserDefaults.standard.removeObject(forKey: "notifications_\(id)")
        }
        currentUser = nil
        isAuthenticated = false
    }

    private func handleAuthSuccess(_ response: AuthResponse) {
        networkManager.setTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        if let userData = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        currentUser = response.user
        isAuthenticated = true
    }
}
