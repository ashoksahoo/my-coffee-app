import SwiftUI

// MARK: - Flavor Wheel View

struct FlavorWheelView: View {
    @Binding var selectedFlavorIds: Set<String>

    @State private var expandedCategory: FlavorNode?
    @State private var expandedSubcategory: FlavorNode?

    // SCA 2016 flavor wheel inspired colors — one per top-level category
    private static let categoryColors: [String: Color] = [
        "floral":           Color(hue: 0.82, saturation: 0.52, brightness: 0.88), // lavender-pink
        "fruity":           Color(hue: 0.02, saturation: 0.82, brightness: 0.90), // warm red
        "sour-fermented":   Color(hue: 0.25, saturation: 0.72, brightness: 0.76), // yellow-green
        "green-vegetative": Color(hue: 0.38, saturation: 0.70, brightness: 0.66), // forest green
        "other":            Color(hue: 0.58, saturation: 0.35, brightness: 0.62), // slate blue
        "roasted":          Color(hue: 0.06, saturation: 0.75, brightness: 0.42), // coffee brown
        "spices":           Color(hue: 0.09, saturation: 0.88, brightness: 0.85), // amber orange
        "nutty-cocoa":      Color(hue: 0.11, saturation: 0.62, brightness: 0.60), // warm cocoa
        "sweet":            Color(hue: 0.14, saturation: 0.78, brightness: 0.96), // golden yellow
    ]

    private func colorForId(_ id: String) -> Color {
        let topLevel = String(id.split(separator: ".").first ?? Substring(id))
        return Self.categoryColors[topLevel] ?? Color.gray
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                Canvas { context, canvasSize in
                    let canvasCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    drawWheel(context: context, center: canvasCenter, size: size)
                }

                centerOverlay(size: size)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, center: center, size: size)
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Center Overlay

    private func centerOverlay(size: CGFloat) -> some View {
        let innerRadius = size * 0.18
        let activeColor: Color = {
            if let sub = expandedSubcategory { return colorForId(sub.id) }
            if let cat = expandedCategory { return colorForId(cat.id) }
            return Color.primary
        }()

        return VStack(spacing: 4) {
            if let subcategory = expandedSubcategory {
                Text(subcategory.name)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(activeColor)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedSubcategory = nil
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(activeColor.opacity(0.8))
                }
            } else if let category = expandedCategory {
                Text(category.name)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(activeColor)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedCategory = nil
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(activeColor.opacity(0.8))
                }
            } else {
                Text("Tap to\nexplore")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: innerRadius * 1.4, height: innerRadius * 1.4)
    }

    // MARK: - Drawing

    private func drawWheel(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        let categories = FlavorWheel.categories
        let innerStart: CGFloat = size * 0.20
        let innerEnd:   CGFloat = size * 0.35
        let midStart:   CGFloat = size * 0.36
        let midEnd:     CGFloat = size * 0.46
        let outerStart: CGFloat = size * 0.47
        let outerEnd:   CGFloat = size * 0.50

        let gapDegrees: Double = 1.5

        if let category = expandedCategory {
            let catColor = colorForId(category.id)

            // Active category arc in inner ring
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                let arcSpan = 360.0 / Double(categories.count)
                let startDeg = Double(idx) * arcSpan - 90 + gapDegrees / 2
                let endDeg   = startDeg + arcSpan - gapDegrees
                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(catColor.opacity(0.75)))
                context.stroke(path, with: .color(catColor.opacity(0.95)), lineWidth: 1.5)

                let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (innerStart + innerEnd) / 2
                let labelPt   = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(category.name)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                context.draw(context.resolve(text), at: labelPt, anchor: .center)
            }

            // Other category arcs — dimmed with their own color
            for (i, cat) in categories.enumerated() {
                guard cat.id != category.id else { continue }
                let thisCatColor = colorForId(cat.id)
                let arcSpan = 360.0 / Double(categories.count)
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg   = startDeg + arcSpan - gapDegrees
                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(thisCatColor.opacity(0.18)))
                context.stroke(path, with: .color(thisCatColor.opacity(0.35)), lineWidth: 0.5)

                let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (innerStart + innerEnd) / 2
                let labelPt   = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(cat.name)
                    .font(.system(size: 8))
                    .foregroundColor(Color.primary.opacity(0.45))
                context.draw(context.resolve(text), at: labelPt, anchor: .center)
            }

            // Middle ring: subcategories
            let subcategories = category.children
            if !subcategories.isEmpty {
                let subArcSpan = 360.0 / Double(subcategories.count)
                for (j, sub) in subcategories.enumerated() {
                    let startDeg = Double(j) * subArcSpan - 90 + gapDegrees / 2
                    let endDeg   = startDeg + subArcSpan - gapDegrees

                    let isExpanded = expandedSubcategory?.id == sub.id
                    let fillOpacity: Double = isExpanded ? 0.72 : (j % 2 == 0 ? 0.38 : 0.52)
                    let path = arcSegmentPath(center: center, innerRadius: midStart, outerRadius: midEnd,
                                              startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                    context.fill(path, with: .color(catColor.opacity(fillOpacity)))
                    context.stroke(path, with: .color(catColor.opacity(0.80)), lineWidth: 1)

                    let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                    let midRadius = (midStart + midEnd) / 2
                    let labelPt   = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                    let text = Text(sub.name)
                        .font(.system(size: 8, weight: isExpanded ? .bold : .medium))
                        .foregroundColor(.white)
                    context.draw(context.resolve(text), at: labelPt, anchor: .center)
                }
            }

            // Outer ring: descriptors of expanded subcategory
            if let subcategory = expandedSubcategory {
                let descriptors = subcategory.children
                if !descriptors.isEmpty {
                    let descArcSpan = 360.0 / Double(descriptors.count)
                    for (k, desc) in descriptors.enumerated() {
                        let startDeg = Double(k) * descArcSpan - 90 + gapDegrees / 2
                        let endDeg   = startDeg + descArcSpan - gapDegrees

                        let isSelected = selectedFlavorIds.contains(desc.id)
                        let fillOpacity: Double = isSelected ? 1.0 : (k % 2 == 0 ? 0.22 : 0.35)
                        let path = arcSegmentPath(center: center, innerRadius: outerStart, outerRadius: outerEnd,
                                                  startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                        context.fill(path, with: .color(catColor.opacity(fillOpacity)))

                        let strokeWidth: CGFloat = isSelected ? 2 : 0.5
                        let strokeOpacity: Double = isSelected ? 1.0 : 0.4
                        context.stroke(path, with: .color(catColor.opacity(strokeOpacity)), lineWidth: strokeWidth)

                        let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                        let midRadius = (outerStart + outerEnd) / 2
                        let labelPt   = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                        let textColor: Color = isSelected ? .white : Color.primary.opacity(0.75)
                        let text = Text(desc.name)
                            .font(.system(size: 7, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(textColor)
                        context.draw(context.resolve(text), at: labelPt, anchor: .center)
                    }
                }
            }

        } else {
            // Default: all 9 categories
            let arcSpan = 360.0 / Double(categories.count)
            for (i, cat) in categories.enumerated() {
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg   = startDeg + arcSpan - gapDegrees
                let catColor = colorForId(cat.id)

                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(catColor.opacity(0.68)))
                context.stroke(path, with: .color(catColor.opacity(0.90)), lineWidth: 1)

                let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (innerStart + innerEnd) / 2
                let labelPt   = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(cat.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                context.draw(context.resolve(text), at: labelPt, anchor: .center)
            }
        }
    }

    // MARK: - Hit Testing

    private func handleTap(at point: CGPoint, center: CGPoint, size: CGFloat) {
        let hit = hitTest(point: point, center: center)
        let angle = hit.angle
        let radius = hit.radius

        let innerStart: CGFloat = size * 0.20
        let innerEnd:   CGFloat = size * 0.35
        let midStart:   CGFloat = size * 0.36
        let midEnd:     CGFloat = size * 0.46
        let outerStart: CGFloat = size * 0.47
        let outerEnd:   CGFloat = size * 0.50

        if radius < innerStart {
            withAnimation(.easeInOut(duration: 0.25)) {
                if expandedSubcategory != nil {
                    expandedSubcategory = nil
                } else {
                    expandedCategory = nil
                }
            }
            return
        }

        let categories = FlavorWheel.categories

        if expandedCategory == nil {
            if radius >= innerStart && radius <= innerEnd {
                let arcSpan = 360.0 / Double(categories.count)
                let normalizedAngle = normalizeAngle(angle)
                let index = Int(normalizedAngle / arcSpan)
                if index >= 0 && index < categories.count {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedCategory = categories[index]
                    }
                }
            }
        } else if let category = expandedCategory {
            if radius >= innerStart && radius <= innerEnd {
                let arcSpan = 360.0 / Double(categories.count)
                let normalizedAngle = normalizeAngle(angle)
                let index = Int(normalizedAngle / arcSpan)
                if index >= 0 && index < categories.count {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if categories[index].id == category.id {
                            expandedCategory = nil
                            expandedSubcategory = nil
                        } else {
                            expandedCategory = categories[index]
                            expandedSubcategory = nil
                        }
                    }
                }
                return
            }

            let subcategories = category.children
            if radius >= midStart && radius <= midEnd && !subcategories.isEmpty {
                let subArcSpan = 360.0 / Double(subcategories.count)
                let normalizedAngle = normalizeAngle(angle)
                let index = Int(normalizedAngle / subArcSpan)
                if index >= 0 && index < subcategories.count {
                    let tappedSub = subcategories[index]
                    if tappedSub.isLeaf {
                        if selectedFlavorIds.contains(tappedSub.id) {
                            selectedFlavorIds.remove(tappedSub.id)
                        } else {
                            selectedFlavorIds.insert(tappedSub.id)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedSubcategory = tappedSub
                        }
                    }
                }
                return
            }

            if let subcategory = expandedSubcategory {
                let descriptors = subcategory.children
                if radius >= outerStart && radius <= outerEnd && !descriptors.isEmpty {
                    let descArcSpan = 360.0 / Double(descriptors.count)
                    let normalizedAngle = normalizeAngle(angle)
                    let index = Int(normalizedAngle / descArcSpan)
                    if index >= 0 && index < descriptors.count {
                        let desc = descriptors[index]
                        if selectedFlavorIds.contains(desc.id) {
                            selectedFlavorIds.remove(desc.id)
                        } else {
                            selectedFlavorIds.insert(desc.id)
                        }
                    }
                }
            }
        }
    }

    private func hitTest(point: CGPoint, center: CGPoint) -> (angle: Angle, radius: CGFloat) {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radius = sqrt(dx * dx + dy * dy)
        let radians = atan2(dy, dx)
        return (Angle(radians: radians), radius)
    }

    private func normalizeAngle(_ angle: Angle) -> Double {
        var degrees = angle.degrees + 90
        while degrees < 0   { degrees += 360 }
        while degrees >= 360 { degrees -= 360 }
        return degrees
    }

    // MARK: - Geometry Helpers

    private func arcSegmentPath(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat,
                                startAngle: Angle, endAngle: Angle) -> Path {
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(CGFloat(angle.radians)),
            y: center.y + radius * sin(CGFloat(angle.radians))
        )
    }
}
