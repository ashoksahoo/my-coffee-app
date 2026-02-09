import SwiftUI

// MARK: - Flavor Wheel View

struct FlavorWheelView: View {
    @Binding var selectedFlavorIds: Set<String>

    @State private var expandedCategory: FlavorNode?
    @State private var expandedSubcategory: FlavorNode?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Draw rings via Canvas for performance
                Canvas { context, canvasSize in
                    let canvasCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    drawWheel(context: context, center: canvasCenter, size: size)
                }

                // Center label and back button
                centerOverlay(size: size)

                // Hit-test overlay
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
        return VStack(spacing: 4) {
            if let subcategory = expandedSubcategory {
                Text(subcategory.name)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedSubcategory = nil
                    }
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.subtle)
                }
            } else if let category = expandedCategory {
                Text(category.name)
                    .font(AppTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                    .multilineTextAlignment(.center)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedCategory = nil
                    }
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.subtle)
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
        let innerEnd: CGFloat = size * 0.35
        let midStart: CGFloat = size * 0.36
        let midEnd: CGFloat = size * 0.46
        let outerStart: CGFloat = size * 0.47
        let outerEnd: CGFloat = size * 0.50

        let gapDegrees: Double = 1.5

        if let category = expandedCategory {
            // Draw the expanded category's inner ring arc as a highlight
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                let arcSpan = 360.0 / Double(categories.count)
                let startDeg = Double(idx) * arcSpan - 90 + gapDegrees / 2
                let endDeg = startDeg + arcSpan - gapDegrees
                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(AppColors.primary.opacity(0.25)))
                context.stroke(path, with: .color(AppColors.primary.opacity(0.4)), lineWidth: 1)

                // Draw label for expanded inner arc
                let midAngle = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (innerStart + innerEnd) / 2
                let labelPoint = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(category.name).font(.system(size: 9, weight: .medium)).foregroundColor(.primary)
                context.draw(context.resolve(text), at: labelPoint, anchor: .center)
            }

            // Draw other categories dimmed
            for (i, cat) in categories.enumerated() {
                guard cat.id != category.id else { continue }
                let arcSpan = 360.0 / Double(categories.count)
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg = startDeg + arcSpan - gapDegrees
                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(AppColors.primary.opacity(0.06)))
                context.stroke(path, with: .color(AppColors.primary.opacity(0.15)), lineWidth: 0.5)
            }

            // Middle ring: subcategories of expanded category
            let subcategories = category.children
            if !subcategories.isEmpty {
                let subArcSpan = 360.0 / Double(subcategories.count)
                for (j, sub) in subcategories.enumerated() {
                    let startDeg = Double(j) * subArcSpan - 90 + gapDegrees / 2
                    let endDeg = startDeg + subArcSpan - gapDegrees

                    let isExpanded = expandedSubcategory?.id == sub.id
                    let opacity: Double = isExpanded ? 0.25 : (j % 2 == 0 ? 0.12 : 0.18)
                    let path = arcSegmentPath(center: center, innerRadius: midStart, outerRadius: midEnd,
                                              startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                    context.fill(path, with: .color(AppColors.primary.opacity(opacity)))
                    context.stroke(path, with: .color(AppColors.primary.opacity(0.3)), lineWidth: 1)

                    // Label
                    let midAngle = Angle.degrees((startDeg + endDeg) / 2)
                    let midRadius = (midStart + midEnd) / 2
                    let labelPoint = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                    let text = Text(sub.name).font(.system(size: 8)).foregroundColor(.primary)
                    context.draw(context.resolve(text), at: labelPoint, anchor: .center)
                }
            }

            // Outer ring: descriptors of expanded subcategory
            if let subcategory = expandedSubcategory {
                let descriptors = subcategory.children
                if !descriptors.isEmpty {
                    let descArcSpan = 360.0 / Double(descriptors.count)
                    for (k, desc) in descriptors.enumerated() {
                        let startDeg = Double(k) * descArcSpan - 90 + gapDegrees / 2
                        let endDeg = startDeg + descArcSpan - gapDegrees

                        let isSelected = selectedFlavorIds.contains(desc.id)
                        let opacity: Double = isSelected ? 0.30 : (k % 2 == 0 ? 0.08 : 0.14)
                        let path = arcSegmentPath(center: center, innerRadius: outerStart, outerRadius: outerEnd,
                                                  startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                        context.fill(path, with: .color(AppColors.primary.opacity(opacity)))

                        let strokeWidth: CGFloat = isSelected ? 2 : 1
                        let strokeOpacity: Double = isSelected ? 0.6 : 0.25
                        context.stroke(path, with: .color(AppColors.primary.opacity(strokeOpacity)), lineWidth: strokeWidth)

                        // Label
                        let midAngle = Angle.degrees((startDeg + endDeg) / 2)
                        let midRadius = (outerStart + outerEnd) / 2
                        let labelPoint = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                        let text = Text(desc.name).font(.system(size: 7)).foregroundColor(.primary)
                        context.draw(context.resolve(text), at: labelPoint, anchor: .center)
                    }
                }
            }
        } else {
            // Default view: all 9 categories in the inner ring
            let arcSpan = 360.0 / Double(categories.count)
            for (i, cat) in categories.enumerated() {
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg = startDeg + arcSpan - gapDegrees

                let opacityPattern: [Double] = [0.10, 0.16, 0.22, 0.13, 0.19, 0.25, 0.11, 0.17, 0.23]
                let opacity = opacityPattern[i % opacityPattern.count]

                let path = arcSegmentPath(center: center, innerRadius: innerStart, outerRadius: innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path, with: .color(AppColors.primary.opacity(opacity)))
                context.stroke(path, with: .color(AppColors.primary.opacity(0.3)), lineWidth: 1)

                // Label
                let midAngle = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (innerStart + innerEnd) / 2
                let labelPoint = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(cat.name).font(.system(size: 9, weight: .medium)).foregroundColor(.primary)
                context.draw(context.resolve(text), at: labelPoint, anchor: .center)
            }
        }
    }

    // MARK: - Hit Testing

    private func handleTap(at point: CGPoint, center: CGPoint, size: CGFloat) {
        let hit = hitTest(point: point, center: center)
        let angle = hit.angle
        let radius = hit.radius

        let innerStart: CGFloat = size * 0.20
        let innerEnd: CGFloat = size * 0.35
        let midStart: CGFloat = size * 0.36
        let midEnd: CGFloat = size * 0.46
        let outerStart: CGFloat = size * 0.47
        let outerEnd: CGFloat = size * 0.50

        // Center tap: navigate back
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
            // Inner ring: tap selects a category
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
            // Inner ring tap: could be tapping the expanded category or another
            if radius >= innerStart && radius <= innerEnd {
                let arcSpan = 360.0 / Double(categories.count)
                let normalizedAngle = normalizeAngle(angle)
                let index = Int(normalizedAngle / arcSpan)
                if index >= 0 && index < categories.count {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if categories[index].id == category.id {
                            // Tap on same category -- collapse
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

            // Middle ring: subcategory selection
            let subcategories = category.children
            if radius >= midStart && radius <= midEnd && !subcategories.isEmpty {
                let subArcSpan = 360.0 / Double(subcategories.count)
                let normalizedAngle = normalizeAngle(angle)
                let index = Int(normalizedAngle / subArcSpan)
                if index >= 0 && index < subcategories.count {
                    let tappedSub = subcategories[index]
                    if tappedSub.isLeaf {
                        // Leaf subcategory: toggle selection directly
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

            // Outer ring: descriptor toggle
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
        // atan2 returns radians from -pi to pi, with 0 at 3 o'clock
        let radians = atan2(dy, dx)
        let angle = Angle(radians: radians)
        return (angle, radius)
    }

    /// Normalizes an angle so that 0 degrees starts at the top (12 o'clock) and increases clockwise.
    /// Input angle is from hitTest (0 at 3 o'clock, positive clockwise).
    private func normalizeAngle(_ angle: Angle) -> Double {
        // hitTest returns 0 at 3 o'clock. Our arcs start at -90 (12 o'clock).
        // Shift by +90 to align, then normalize to 0..<360
        var degrees = angle.degrees + 90
        while degrees < 0 { degrees += 360 }
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
