import Foundation

@MainActor
final class MonitoringDetailViewModel: ObservableObject {
    @Published var records: [MonitorDetailRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: MonitoringAPI
    private let centerId: String

    init(centerId: String, api: MonitoringAPI = MockMonitoringAPI()) {
        self.centerId = centerId
        self.api = api
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let data = try await api.fetchDetail(centerId: centerId)
            records = data.records
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
