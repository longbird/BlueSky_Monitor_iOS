import Foundation

@MainActor
final class MonitoringChartViewModel: ObservableObject {
    @Published var chartSeries: [String: [ChartValuePoint]] = [:]
    @Published var isLoading = false

    private let centerId: String
    private let minutes: Int
    private let api: MonitoringAPI

    init(centerId: String, minutes: Int = 30, api: MonitoringAPI = LiveMonitoringAPI()) {
        self.centerId = centerId
        self.minutes = minutes
        self.api = api
    }

    func load() async {
        guard !centerId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await api.fetchChart(centerId: centerId, minutes: minutes)
            chartSeries = [
                "cpu": data.points.map { ChartValuePoint(t: $0.t, v: $0.cpu) },
                "mem": data.points.map { ChartValuePoint(t: $0.t, v: $0.mem) },
                "disk": data.points.map { ChartValuePoint(t: $0.t, v: $0.disk) },
                "rx": data.points.map { ChartValuePoint(t: $0.t, v: $0.rx) },
                "tx": data.points.map { ChartValuePoint(t: $0.t, v: $0.tx) }
            ]
        } catch {
            NSLog("[MonitoringChartVM] error=%@", String(describing: error))
        }
    }
}
