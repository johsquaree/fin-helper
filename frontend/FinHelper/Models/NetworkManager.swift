import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(String)
    case networkError(String)
    case validationError(String)
    case unauthorized

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Geçersiz URL adresi"
        case .noData:
            return "Sunucudan veri alınamadı"
        case .decodingError(let detail):
            return "Sunucudan gelen veri işlenemedi: \(detail)"
        case .serverError(let message):
            if message.contains("409") { return "Bu e-posta adresi zaten kullanımda" }
            if message.contains("404") { return "Bulunamadı" }
            if message.contains("500") { return "Sunucu hatası, lütfen daha sonra tekrar deneyin" }
            return "Sunucu hatası: \(message)"
        case .networkError(let message):
            return "Bağlantı hatası: \(message)"
        case .validationError(let message):
            return "Doğrulama hatası: \(message)"
        case .unauthorized:
            return "Oturum süresi doldu, lütfen tekrar giriş yapın"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://fin-helper-production.up.railway.app"

    private var accessToken: String?
    private var refreshToken: String?

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    private init() {
        accessToken = UserDefaults.standard.string(forKey: "accessToken")
        refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
    }

    func setTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        UserDefaults.standard.set(accessToken, forKey: "accessToken")
        UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
    }

    // Eski kod uyumluluğu için
    func setAuthToken(_ token: String) {
        self.accessToken = token
        UserDefaults.standard.set(token, forKey: "accessToken")
    }

    func clearAuthToken() {
        self.accessToken = nil
        self.refreshToken = nil
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "authToken")
    }

    func makeRequest<T: Decodable>(endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws -> T {
        do {
            return try await performRequest(endpoint: endpoint, method: method, body: body)
        } catch NetworkError.unauthorized {
            // Token süresi dolmuş — yenilemeyi dene
            try await renewAccessToken()
            return try await performRequest(endpoint: endpoint, method: method, body: body)
        }
    }

    private func performRequest<T: Decodable>(endpoint: String, method: HTTPMethod, body: Data?) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Geçersiz sunucu yanıtı")
        }

        switch httpResponse.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        throw NetworkError.decodingError("Eksik alan: \(key.stringValue)")
                    case .typeMismatch(_, let context):
                        throw NetworkError.decodingError("Tip uyuşmazlığı: \(context.debugDescription)")
                    case .valueNotFound(_, let context):
                        throw NetworkError.decodingError("Değer bulunamadı: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        throw NetworkError.decodingError("Bozuk veri: \(context.debugDescription)")
                    @unknown default:
                        throw NetworkError.decodingError(error.localizedDescription)
                    }
                }
                throw NetworkError.decodingError(error.localizedDescription)
            }
        case 400:
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NetworkError.validationError(message)
            }
            throw NetworkError.validationError("Geçersiz istek")
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.serverError("404")
        case 409:
            throw NetworkError.serverError("409")
        case 500:
            throw NetworkError.serverError("500")
        default:
            throw NetworkError.serverError("\(httpResponse.statusCode)")
        }
    }

    private func renewAccessToken() async throws {
        guard let token = refreshToken else {
            throw NetworkError.unauthorized
        }

        guard let url = URL(string: baseURL + "/api/auth/refresh-token") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["refreshToken": token])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            clearAuthToken()
            throw NetworkError.unauthorized
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["accessToken"] as? String,
              let newRefreshToken = json["refreshToken"] as? String else {
            throw NetworkError.unauthorized
        }

        setTokens(accessToken: newAccessToken, refreshToken: newRefreshToken)
    }
}
