import Foundation

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var items: [MonitorSummaryItem] = []
    @Published var centers: [CenterInfo] = []
    @Published var selectedCenterId: String = ""
    @Published var centerSearchText: String = ""
    @Published var chartSeries: [String: [ChartValuePoint]] = [:]
    @Published var chartMinutes: Int = 60
    @Published var isLoading = false
    @Published var isUserInteracting = false
    @Published var errorMessage: String?

    private var refreshTask: Task<Void, Never>?

    private let api: MonitoringAPI

    init(api: MonitoringAPI = MockMonitoringAPI()) {
        self.api = api
    }

    func loadCenters() async {
        do {
            let list = try await api.fetchCenters()
            centers = [CenterInfo(centerId: "", centerName: "전체")] + list.filter { !$0.centerId.isEmpty }
        } catch {
            NSLog("[MonitoringVM] centers error=%@", String(describing: error))
        }
    }

    var filteredCenters: [CenterInfo] {
        let query = centerSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return centers }
        return centers.filter {
            $0.centerId.lowercased().contains(query) || $0.centerName.lowercased().contains(query)
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    func load() async {
        if selectedCenterId.isEmpty {
            items = []
            errorMessage = nil
            NSLog("[MonitoringVM] load skipped (no center)")
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        NSLog("[MonitoringVM] load start center=%@", selectedCenterId)
        do {
            let data = try await api.fetchSummary(centerId: selectedCenterId)
            items = data.items
            NSLog("[MonitoringVM] load success count=%d", items.count)
        } catch {
            NSLog("[MonitoringVM] load error=%@", String(describing: error))
            errorMessage = error.localizedDescription
        }
    }

    func loadCharts() async {
        guard !selectedCenterId.isEmpty else {
            chartSeries = [:]
            return
        }

        do {
            let data = try await api.fetchChart(centerId: selectedCenterId, minutes: chartMinutes)
            chartSeries = [
                "cpu": data.points.map { ChartValuePoint(t: $0.t, v: $0.cpu) },
                "mem": data.points.map { ChartValuePoint(t: $0.t, v: $0.mem) },
                "disk": data.points.map { ChartValuePoint(t: $0.t, v: $0.disk) },
                "rx": data.points.map { ChartValuePoint(t: $0.t, v: $0.rx) },
                "tx": data.points.map { ChartValuePoint(t: $0.t, v: $0.tx) }
            ]
        } catch {
            NSLog("[MonitoringVM] chart error=%@", String(describing: error))
        }
    }

    func startAutoRefresh(intervalSeconds: Double = 3.0) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if !self.isUserInteracting {
                    await self.load()
                    await self.loadCharts()
                }
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
