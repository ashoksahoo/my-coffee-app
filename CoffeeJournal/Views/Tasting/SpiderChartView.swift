import SwiftUI

// MARK: - Radar Chart Shape

struct RadarChartShape: Shape {
    let data: [Double]
    let axisCount: Int

    func path(in rect: CGRect) -> Path {
        guard axisCount >= 3, data.count == axisCount else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angleStep = 2 * .pi / Double(axisCount)

        var path = Path()
        for i in 0..<axisCount {
            let angle = angleStep * Double(i) - .pi / 2
            let value = max(0, min(1, data[i]))
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle) * value) * radius,
                y: center.y + CGFloat(sin(angle) * value) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Spider Chart View

struct SpiderChartView: View {
    let values: [Double]
    let labels: [String]
    var gridLevels: Int = 5

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 * 0.75 // Leave room for labels
            let axisCount = values.count
            let angleStep = 2 * .pi / Double(axisCount)

            ZStack {
                // Concentric grid polygons
                ForEach(1...gridLevels, id: \.self) { level in
                    let scale = Double(level) / Double(gridLevels)
                    RadarChartShape(
                        data: Array(repeating: scale, count: axisCount),
                        axisCount: axisCount
                    )
                    .stroke(AppColors.muted, lineWidth: 0.5)
                    .frame(width: size * 0.75, height: size * 0.75)
                    .position(center)
                }

                // Axis lines
                ForEach(0..<axisCount, id: \.self) { i in
                    let angle = angleStep * Double(i) - .pi / 2
                    let endpoint = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * radius,
                        y: center.y + CGFloat(sin(angle)) * radius
                    )
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: endpoint)
                    }
                    .stroke(AppColors.muted, lineWidth: 0.5)
                }

                // Data polygon fill
                RadarChartShape(data: values, axisCount: axisCount)
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: size * 0.75, height: size * 0.75)
                    .position(center)

                // Data polygon stroke
                RadarChartShape(data: values, axisCount: axisCount)
                    .stroke(AppColors.primary, lineWidth: 2)
                    .frame(width: size * 0.75, height: size * 0.75)
                    .position(center)

                // Data points
                ForEach(0..<axisCount, id: \.self) { i in
                    let angle = angleStep * Double(i) - .pi / 2
                    let value = max(0, min(1, values[i]))
                    let point = CGPoint(
                        x: center.x + CGFloat(cos(angle) * value) * radius,
                        y: center.y + CGFloat(sin(angle) * value) * radius
                    )
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 8, height: 8)
                        .position(point)
                }

                // Labels
                ForEach(0..<axisCount, id: \.self) { i in
                    let angle = angleStep * Double(i) - .pi / 2
                    let labelRadius = radius + 16
                    let labelPoint = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * labelRadius,
                        y: center.y + CGFloat(sin(angle)) * labelRadius
                    )
                    Text(labels[i])
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondary)
                        .position(labelPoint)
                }
            }
        }
    }

    // MARK: - Convenience Constructor

    static func fromTastingNote(_ note: TastingNote) -> SpiderChartView {
        SpiderChartView(
            values: [
                Double(note.acidity) / 5.0,
                Double(note.body) / 5.0,
                Double(note.sweetness) / 5.0,
            ],
            labels: ["Acidity", "Body", "Sweetness"]
        )
    }
}
