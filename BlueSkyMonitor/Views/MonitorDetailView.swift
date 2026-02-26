import SwiftUI

struct MonitorDetailView: View {
    let item: MonitorSummaryItem

    var body: some View {
        List {
            Section(header: Text("서버 상태")) {
                ForEach(mockServers) { server in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(server.serverId.uppercased())
                                .font(.headline)
                            Spacer()
                            StatusBadge(status: server.status)
                        }
                        Text("
\(server.host):\(server.port)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            MetricView(title: "CPU", value: String(format: "%.1f%%", server.cpu))
                            MetricView(title: "MEM", value: String(format: "%.1f%%", server.mem))
                            MetricView(title: "DISK", value: String(format: "%.1f%%", server.disk))
                        }
                        HStack {
                            MetricView(title: "RX", value: ByteFormatter.format(server.rxBps))
                            MetricView(title: "TX", value: ByteFormatter.format(server.txBps))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle(item.centerName)
    }

    private var mockServers: [MonitorServer] {
        [
            MonitorServer(serverId: "cmd", host: item.ipPbxIp, port: 1234, status: item.status, cpu: item.sysCpu, mem: item.sysMem, disk: item.storageUsedPercent, rxBps: item.netRxBytes, txBps: item.netTxBytes, lastUpdated: Date())
        ]
    }
}
