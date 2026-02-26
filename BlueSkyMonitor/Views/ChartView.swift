import SwiftUI

struct MultiLineChartView: View {
    struct Series: Identifiable {
        let id: String
        let name: String
        let color: Color
        let points: [ChartValuePoint]
        let scale: @Sendable (Double) -> Double
        let yMax: Double
    }

    let series: [Series]
    let windowSeconds: TimeInterval
    let maxPoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    if let latest = latestTimestamp {
                        let windowStart = latest.addingTimeInterval(-windowSeconds)
                        ForEach(series) { item in
                            LineShape(
                                points: item.points,
                                scale: item.scale,
                                windowStart: windowStart,
                                windowSeconds: windowSeconds,
                                maxPoints: maxPoints,
                                yMax: item.yMax
                            )
                            .stroke(item.color, lineWidth: 2)
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .frame(height: 180)

            HStack(spacing: 12) {
                ForEach(series) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private var latestTimestamp: Date? {
        series
            .flatMap { $0.points }
            .map { $0.t }
            .max()
    }
}

private struct LineShape: Shape {
    let points: [ChartValuePoint]
    let scale: @Sendable (Double) -> Double
    let windowStart: Date
    let windowSeconds: TimeInterval
    let maxPoints: Int
    let yMax: Double

    func path(in rect: CGRect) -> Path {
        var filtered = points
            .filter { $0.t >= windowStart }
            .sorted { $0.t < $1.t }

        guard filtered.count > 1 else { return Path() }

        if maxPoints > 0, filtered.count > maxPoints {
            let strideValue = max(1, filtered.count / maxPoints)
            filtered = stride(from: 0, to: filtered.count, by: strideValue).map { filtered[$0] }
        }

        let minV = 0.0
        let maxV = max(yMax, minV + 0.0001)
        let range = max(maxV - minV, 0.0001)

        func yPosition(_ value: Double) -> CGFloat {
            let normalized = (value - minV) / range
            return rect.height * (1 - normalized)
        }

        func xPosition(_ date: Date) -> CGFloat {
            let delta = date.timeIntervalSince(windowStart)
            let progress = max(0, min(1, delta / windowSeconds))
            return rect.width * progress
        }

        var path = Path()
        for (index, point) in filtered.enumerated() {
            let x = xPosition(point.t)
            let y = yPosition(scale(point.v))
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
