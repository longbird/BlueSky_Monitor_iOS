import SwiftUI

struct MonitorDetailView: View {
    let item: MonitorSummaryItem
    @StateObject private var viewModel: MonitoringDetailViewModel

    init(item: MonitorSummaryItem) {
        self.item = item
        _viewModel = StateObject(wrappedValue: MonitoringDetailViewModel(centerId: item.centerId))
    }

    var body: some View {
        List {
            Section(header: Text("센터 요약")) {
                HStack {
                    Text("상태")
                    Spacer()
                    StatusBadge(status: item.status)
                }
                HStack {
                    Text("IP-PBX")
                    Spacer()
                    Text("\(item.ipPbxIp):\(item.ipPbxPort)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    MetricView(title: "CPU", value: String(format: "%.1f%%", item.sysCpu))
                    MetricView(title: "MEM", value: String(format: "%.1f%%", item.sysMem))
                    MetricView(title: "DISK", value: String(format: "%.1f%%", item.storageUsedPercent))
                }
            }

            Section(header: Text("이력 (상세)")) {
                if viewModel.isLoading {
                    ProgressView("불러오는 중...")
                }
                ForEach(viewModel.records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SEQ #\(record.seq)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            MetricView(title: "CPU", value: String(format: "%.1f%%", record.cpu))
                            MetricView(title: "MEM", value: String(format: "%.1f%%", record.mem))
                            MetricView(title: "DISK", value: String(format: "%.1f%%", record.disk))
                        }
                        HStack {
                            MetricView(title: "RX", value: ByteFormatter.format(record.rxBytes))
                            MetricView(title: "TX", value: ByteFormatter.format(record.txBytes))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle(item.centerName)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}
