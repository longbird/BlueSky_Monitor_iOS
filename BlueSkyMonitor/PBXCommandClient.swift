import Foundation

enum PBXCommandError: Error {
    case missingKey
    case invalidURL
    case requestFailed
}

struct PBXCommandClient {
    private static let headerName = "X-BSAUTH-TOKEN"

    static func sendCommand(ip: String, callCenterCd: String, command: String) async throws -> Bool {
        let token = try jwt(callCenterCd: callCenterCd)
        var components = URLComponents()
        components.scheme = "http"
        components.host = ip
        components.path = "/fs_cmd.php"
        components.queryItems = [
            URLQueryItem(name: "auth", value: "ON"),
            URLQueryItem(name: "do", value: command)
        ]
        guard let url = components.url else {
            throw PBXCommandError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: headerName)

        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        return statusCode == 200
    }

    static func fetchVersion(ip: String, callCenterCd: String) async throws -> Int {
        let token = try jwt(callCenterCd: callCenterCd)
        var components = URLComponents()
        components.scheme = "http"
        components.host = ip
        components.path = "/fs_version.php"
        guard let url = components.url else {
            throw PBXCommandError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: headerName)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else { throw PBXCommandError.requestFailed }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["version"] as? Int ?? 0
    }

    private static func jwt(callCenterCd: String) throws -> String {
        guard let keyURL = Bundle.main.url(forResource: "pbx_private_key", withExtension: "pem"),
              let keyData = try? Data(contentsOf: keyURL),
              let pem = String(data: keyData, encoding: .utf8) else {
            throw PBXCommandError.missingKey
        }
        return try PBXJWT.token(callCenterCd: callCenterCd, manager: true, privateKeyPEM: pem)
    }
}
