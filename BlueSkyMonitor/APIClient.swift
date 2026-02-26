import Foundation

protocol MonitoringAPI {
    func fetchSummary(centerId: String?) async throws -> MonitorSummaryData
    func fetchCenters() async throws -> [CenterInfo]
    func fetchDetail(centerId: String) async throws -> MonitorDetailData
    func fetchChart(centerId: String, minutes: Int?) async throws -> ChartResponseData
}

final class LiveMonitoringAPI: MonitoringAPI {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder.blueSkyDecoder()
    }

    func fetchSummary(centerId: String? = nil) async throws -> MonitorSummaryData {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent("api/v1/monitor/summary"), resolvingAgainstBaseURL: false)
        if let centerId, !centerId.isEmpty {
            components?.queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        }
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = try makeRequest(url: url)
        logRequest(label: "summary", request: request)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "summary", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<MonitorSummaryData>.self, from: data)
        guard wrapped.success, let payload = wrapped.data else {
            let message = wrapped.message ?? "목록 불러오기 실패"
            throw NSError(domain: "MonitoringAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return payload
    }

    func fetchCenters() async throws -> [CenterInfo] {
        let url = AppConfig.baseURL.appendingPathComponent("api/v1/monitor/centers")
        let request = try makeRequest(url: url)
        logRequest(label: "centers", request: request)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "centers", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<[CenterInfo]>.self, from: data)
        guard wrapped.success, let payload = wrapped.data else {
            let message = wrapped.message ?? "센터 목록 불러오기 실패"
            throw NSError(domain: "MonitoringAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return payload
    }

    func fetchDetail(centerId: String) async throws -> MonitorDetailData {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent("api/v1/monitor/detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = try makeRequest(url: url)
        logRequest(label: "detail", request: request)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "detail", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<MonitorDetailData>.self, from: data)
        guard wrapped.success, let payload = wrapped.data else {
            let message = wrapped.message ?? "상세 불러오기 실패"
            throw NSError(domain: "MonitoringAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return payload
    }

    func fetchChart(centerId: String, minutes: Int? = nil) async throws -> ChartResponseData {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent("api/v1/monitor/chart"), resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "centerId", value: centerId)]
        if let minutes {
            queryItems.append(URLQueryItem(name: "minutes", value: String(minutes)))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = try makeRequest(url: url)
        logRequest(label: "chart", request: request)
        let (data, response) = try await session.data(for: request)
        logResponse(label: "chart", response: response, data: data)
        let wrapped = try decoder.decode(APIResponse<ChartResponseData>.self, from: data)
        guard wrapped.success, let payload = wrapped.data else {
            let message = wrapped.message ?? "차트 불러오기 실패"
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

    private func logRequest(label: String, request: URLRequest) {
        let url = request.url?.absoluteString ?? "<no-url>"
        let hasToken = request.value(forHTTPHeaderField: "Authorization") != nil
        NSLog("[MonitoringAPI] %@ request url=%@ auth=%@", label, url, hasToken ? "yes" : "no")
    }

    private func logResponse(label: String, response: URLResponse, data: Data) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
        NSLog("[MonitoringAPI] %@ status=%d body=%@", label, statusCode, body)
    }
}

final class MockMonitoringAPI: MonitoringAPI {
    func fetchSummary(centerId: String? = nil) async throws -> MonitorSummaryData {
        let all = [
            MonitorSummaryItem(centerId: "C00001", centerName: "(주)아이콘소프트", connect: true, sysCpu: 12.3, sysMem: 45.8, storageUsedPercent: 71.2, netRxBytes: 123_456_789, netTxBytes: 98_765_432, ipPbxIp: "10.0.0.12", ipPbxPort: 5060, status: .good),
            MonitorSummaryItem(centerId: "C00002", centerName: "콜밸런싱콜센터1", connect: false, sysCpu: 0.0, sysMem: 0.0, storageUsedPercent: 0.0, netRxBytes: 0, netTxBytes: 0, ipPbxIp: "10.0.1.12", ipPbxPort: 5060, status: .offline)
        ]
        let items = centerId == nil || centerId?.isEmpty == true ? all : all.filter { $0.centerId == centerId }
        return MonitorSummaryData(timestamp: Date(), items: items)
    }

    func fetchCenters() async throws -> [CenterInfo] {
        return [
            CenterInfo(centerId: "", centerName: "전체"),
            CenterInfo(centerId: "C00001", centerName: "(주)아이콘소프트"),
            CenterInfo(centerId: "C00002", centerName: "콜밸런싱콜센터1")
        ]
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

    func fetchChart(centerId: String, minutes: Int? = nil) async throws -> ChartResponseData {
        let points = Array((0..<12).map { idx in
            ChartPoint(
                t: Date().addingTimeInterval(Double(-idx) * 300),
                cpu: Double.random(in: 10...80),
                mem: Double.random(in: 10...80),
                disk: Double.random(in: 10...80),
                rx: Double.random(in: 10_000...200_000),
                tx: Double.random(in: 10_000...200_000)
            )
        }.reversed())
        return ChartResponseData(points: points)
    }
}
