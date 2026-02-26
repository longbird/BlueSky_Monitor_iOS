import Foundation

protocol AuthAPI {
    func login(mgrId: String, mgrPwd: String) async throws -> LoginResponseData
    func refresh(refreshToken: String) async throws -> LoginResponseData
}

final class LiveAuthAPI: AuthAPI {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder.blueSkyDecoder()
    }

    func login(mgrId: String, mgrPwd: String) async throws -> LoginResponseData {
        let url = AppConfig.baseURL.appendingPathComponent("api/v1/auth/login")
        let body = LoginRequest(mgrId: mgrId, mgrPwd: mgrPwd)
        let request = try makeJSONRequest(url: url, body: body)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "login", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<LoginResponseData>.self, from: data)
        guard let payload = wrapped.data else { throw URLError(.cannotParseResponse) }
        return payload
    }

    func refresh(refreshToken: String) async throws -> LoginResponseData {
        let url = AppConfig.baseURL.appendingPathComponent("api/v1/auth/refresh")
        let body = RefreshRequest(refreshToken: refreshToken)
        let request = try makeJSONRequest(url: url, body: body)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "refresh", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<LoginResponseData>.self, from: data)
        guard let payload = wrapped.data else { throw URLError(.cannotParseResponse) }
        return payload
    }

    private func makeJSONRequest<T: Codable>(url: URL, body: T) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func logResponse(label: String, response: URLResponse, data: Data) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        print("[AuthAPI] \(label) status=\(statusCode) body=\(body)")
    }
}
