import SwiftUI

struct MultiLineChartView: View {
    struct Series: Identifiable {
        let id: String
        let name: String
        let color: Color
        let points: [ChartPoint]
        let scale: (Double) -> Double
    }

    let series: [Series]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack {
                    ForEach(series) { item in
                        LineShape(points: item.points, scale: item.scale)
                            .stroke(item.color, lineWidth: 2)
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
}

private struct LineShape: Shape {
    let points: [ChartPoint]
    let scale: (Double) -> Double

    func path(in rect: CGRect) -> Path {
        guard points.count > 1 else { return Path() }
        let values = points.map { scale($0.v) }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(maxV - minV, 0.0001)

        func yPosition(_ value: Double) -> CGFloat {
            let normalized = (value - minV) / range
            return rect.height * (1 - normalized)
        }

        let stepX = rect.width / CGFloat(max(points.count - 1, 1))
        var path = Path()
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * stepX
            let y = yPosition(value)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}
