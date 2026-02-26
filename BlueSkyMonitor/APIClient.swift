import Foundation

protocol MonitoringAPI {
    func fetchSummary() async throws -> MonitorSummaryData
    func fetchDetail(centerId: String) async throws -> MonitorDetailData
}

final class LiveMonitoringAPI: MonitoringAPI {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder.blueSkyDecoder()
    }

    func fetchSummary() async throws -> MonitorSummaryData {
        let url = AppConfig.baseURL.appendingPathComponent("api/v1/monitor/summary")
        let request = try makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let wrapped = try decoder.decode(APIResponse<MonitorSummaryData>.self, from: data)
        guard let payload = wrapped.data else { throw URLError(.cannotParseResponse) }
        return payload
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailData {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent("api/v1/monitor/detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = try makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let wrapped = try decoder.decode(APIResponse<MonitorDetailData>.self, from: data)
        guard let payload = wrapped.data else { throw URLError(.cannotParseResponse) }
        return payload
    }

    private func makeRequest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

final class MockMonitoringAPI: MonitoringAPI {
    func fetchSummary() async throws -> MonitorSummaryData {
        return MonitorSummaryData(
            timestamp: Date(),
            items: [
                MonitorSummaryItem(centerId: "C00001", centerName: "(주)아이콘소프트", connect: true, sysCpu: 12.3, sysMem: 45.8, storageUsedPercent: 71.2, netRxBytes: 123_456_789, netTxBytes: 98_765_432, ipPbxIp: "10.0.0.12", ipPbxPort: 5060, status: .good),
                MonitorSummaryItem(centerId: "C00002", centerName: "콜밸런싱콜센터1", connect: false, sysCpu: 0.0, sysMem: 0.0, storageUsedPercent: 0.0, netRxBytes: 0, netTxBytes: 0, ipPbxIp: "10.0.1.12", ipPbxPort: 5060, status: .offline)
            ]
        )
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailData {
        return MonitorDetailData(
            centerId: centerId,
            records: [
                MonitorDetailRecord(seq: 1, centerId: centerId, cpu: 15.1, mem: 62.3, disk: 80.4, rxBytes: 123_456, txBytes: 654_321),
                MonitorDetailRecord(seq: 2, centerId: centerId, cpu: 20.5, mem: 58.2, disk: 81.0, rxBytes: 223_456, txBytes: 754_321)
            ]
        )
    }
}
