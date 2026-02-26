import Foundation

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var items: [MonitorSummaryItem] = []
    @Published var centers: [CenterInfo] = []
    @Published var selectedCenterId: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

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

    func load() async {
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
}
