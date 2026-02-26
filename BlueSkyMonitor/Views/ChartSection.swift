import SwiftUI

struct ChartSection: View {
    let chartSeries: [String: [ChartValuePoint]]

    private let colors: [String: Color] = [
        "cpu": .red,
        "mem": .blue,
        "disk": .orange,
        "rx": .green,
        "tx": .purple
    ]

    private let names: [String: String] = [
        "cpu": "CPU",
        "mem": "RAM",
        "disk": "HDD",
        "rx": "RX",
        "tx": "TX"
    ]

    var body: some View {
        let series = buildSeries()
        VStack(alignment: .leading, spacing: 8) {
            Text("차트 (30분)")
                .font(.headline)
            MultiLineChartView(series: series, windowSeconds: 30 * 60, maxPoints: 100)
        }
        .padding(.horizontal)
    }

    private func buildSeries() -> [MultiLineChartView.Series] {
        let metrics = ["cpu", "mem", "disk", "rx", "tx"]
        return metrics.compactMap { key in
            guard let points = chartSeries[key] else { return nil }
            let scale: @Sendable (Double) -> Double = { value in
                if key == "rx" || key == "tx" {
                    return value / 1000.0
                }
                return value
            }
            let yMax = chartMax(for: key, points: points, scale: scale)
            return MultiLineChartView.Series(
                id: key,
                name: names[key] ?? key.uppercased(),
                color: colors[key] ?? .gray,
                points: points,
                scale: scale,
                yMax: yMax
            )
        }
    }

    private func chartMax(for key: String, points: [ChartValuePoint], scale: @Sendable (Double) -> Double) -> Double {
        if key == "rx" || key == "tx" {
            let maxValue = points.map { scale($0.v) }.max() ?? 0
            let boosted = maxValue * 1.3
            return max(100.1, boosted)
        }
        return 100.1
    }
    }
}
