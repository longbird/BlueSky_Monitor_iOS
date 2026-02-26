import Foundation

@MainActor
final class MonitoringViewModel: ObservableObject {
    @Published var items: [MonitorSummaryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: MonitoringAPI

    init(api: MonitoringAPI = MockMonitoringAPI()) {
        self.api = api
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        NSLog("[MonitoringVM] load start")
        do {
            let data = try await api.fetchSummary()
            items = data.items
            NSLog("[MonitoringVM] load success count=%d", items.count)
        } catch {
            NSLog("[MonitoringVM] load error=%@", String(describing: error))
            errorMessage = error.localizedDescription
        }
    }
}
