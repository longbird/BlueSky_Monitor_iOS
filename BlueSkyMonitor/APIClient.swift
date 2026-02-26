import Foundation

protocol MonitoringAPI {
    func fetchSummary() async throws -> MonitorSummaryResponse
    func fetchDetail(centerId: String) async throws -> MonitorDetailResponse
}

struct APIConfig {
    static let baseURL = URL(string: "https://your-api.domain/api/v1")!
}

final class LiveMonitoringAPI: MonitoringAPI {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func fetchSummary() async throws -> MonitorSummaryResponse {
        let url = APIConfig.baseURL.appendingPathComponent("monitor/summary")
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(MonitorSummaryResponse.self, from: data)
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailResponse {
        var components = URLComponents(url: APIConfig.baseURL.appendingPathComponent("monitor/detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        guard let url = components?.url else { throw URLError(.badURL) }
        let (data, _) = try await session.data(from: url)
        return try decoder.decode(MonitorDetailResponse.self, from: data)
    }
}

final class MockMonitoringAPI: MonitoringAPI {
    func fetchSummary() async throws -> MonitorSummaryResponse {
        return MonitorSummaryResponse(
            timestamp: Date(),
            items: [
                MonitorSummaryItem(centerId: "01", centerName: "서울센터", connect: true, sysCpu: 12.3, sysMem: 45.8, storageUsedPercent: 71.2, netRxBytes: 123_456_789, netTxBytes: 98_765_432, ipPbxIp: "10.0.0.12", status: .good),
                MonitorSummaryItem(centerId: "02", centerName: "부산센터", connect: false, sysCpu: 0.0, sysMem: 0.0, storageUsedPercent: 0.0, netRxBytes: 0, netTxBytes: 0, ipPbxIp: "10.0.1.12", status: .offline)
            ]
        )
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailResponse {
        return MonitorDetailResponse(
            centerId: centerId,
            centerName: centerId == "01" ? "서울센터" : "부산센터",
            servers: [
                MonitorServer(serverId: "cmd", host: "10.0.0.10", port: 1234, status: .good, cpu: 18.2, mem: 62.1, disk: 80.4, rxBps: 123_000, txBps: 54_000, lastUpdated: Date())
            ]
        )
    }
}
