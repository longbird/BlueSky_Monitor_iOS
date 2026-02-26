import SwiftUI

struct MonitorRowView: View {
    let item: MonitorSummaryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.centerName)
                    .font(.headline)
                Spacer()
                StatusBadge(status: item.status)
            }

            HStack(spacing: 12) {
                MetricView(title: "CPU", value: String(format: "%.1f%%", item.sysCpu))
                MetricView(title: "MEM", value: String(format: "%.1f%%", item.sysMem))
                MetricView(title: "DISK", value: String(format: "%.1f%%", item.storageUsedPercent))
            }

            HStack(spacing: 12) {
                MetricView(title: "RX", value: ByteFormatter.format(item.netRxBytes))
                MetricView(title: "TX", value: ByteFormatter.format(item.netTxBytes))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusBadge: View {
    let status: MonitorStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundColor(.white)
            .background(status.color)
            .cornerRadius(8)
    }
}

extension MonitorStatus {
    var color: Color {
        switch self {
        case .good: return .green
        case .normal: return .blue
        case .bad: return .orange
        case .offline: return .red
        case .unused: return .gray
        }
    }
}

enum ByteFormatter {
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
