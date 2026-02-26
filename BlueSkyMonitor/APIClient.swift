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
        let url = AppConfig.baseURL.appendingPathComponent("api/v1/monitor/centers")
        let request = try makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "summary", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<[CenterInfo]>.self, from: data)
        guard wrapped.success, let centers = wrapped.data else {
            let message = wrapped.message ?? "목록 불러오기 실패"
            throw NSError(domain: "MonitoringAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        let items = centers.map {
            MonitorSummaryItem(
                centerId: $0.centerId,
                centerName: $0.centerName,
                connect: false,
                sysCpu: 0,
                sysMem: 0,
                storageUsedPercent: 0,
                netRxBytes: 0,
                netTxBytes: 0,
                ipPbxIp: "",
                ipPbxPort: 0,
                status: .unused
            )
        }
        return MonitorSummaryData(timestamp: Date(), items: items)
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailData {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent("api/v1/monitor/detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = try makeRequest(url: url)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "detail", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<MonitorDetailData>.self, from: data)
        guard wrapped.success, let payload = wrapped.data else {
            let message = wrapped.message ?? "상세 불러오기 실패"
            throw NSError(domain: "MonitoringAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
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

    private func logResponse(label: String, response: URLResponse, data: Data) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        NSLog("[MonitoringAPI] %@ status=%d body=%@", label, statusCode, body)
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
