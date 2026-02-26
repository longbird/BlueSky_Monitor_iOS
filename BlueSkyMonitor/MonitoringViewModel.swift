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

        do {
            let response = try await api.fetchSummary()
            items = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
