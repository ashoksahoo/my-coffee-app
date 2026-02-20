import SwiftUI

// MARK: - Ring Radii

private struct RingRadii {
    let innerStart, innerEnd: CGFloat
    let midStart,   midEnd:   CGFloat
    let outerStart, outerEnd: CGFloat
    let holeRadius:           CGFloat   // usable center area radius

    // Font sizes scale with ring thickness
    var innerFontSize: CGFloat { max(7, (innerEnd - innerStart) * 0.36) }
    var midFontSize:   CGFloat { max(8, (midEnd   - midStart)   * 0.40) }
    var outerFontSize: CGFloat { max(9, (outerEnd - outerStart) * 0.42) }
}

// MARK: - Flavor Wheel View

struct FlavorWheelView: View {
    @Binding var selectedFlavorIds: Set<String>

    @State private var expandedCategory:    FlavorNode?
    @State private var expandedSubcategory: FlavorNode?

    // SCA 2016 flavor wheel inspired colors — one per top-level category
    private static let categoryColors: [String: Color] = [
        "floral":           Color(hue: 0.82, saturation: 0.52, brightness: 0.88),
        "fruity":           Color(hue: 0.02, saturation: 0.82, brightness: 0.90),
        "sour-fermented":   Color(hue: 0.25, saturation: 0.72, brightness: 0.76),
        "green-vegetative": Color(hue: 0.38, saturation: 0.70, brightness: 0.66),
        "other":            Color(hue: 0.58, saturation: 0.35, brightness: 0.62),
        "roasted":          Color(hue: 0.06, saturation: 0.75, brightness: 0.42),
        "spices":           Color(hue: 0.09, saturation: 0.88, brightness: 0.85),
        "nutty-cocoa":      Color(hue: 0.11, saturation: 0.62, brightness: 0.60),
        "sweet":            Color(hue: 0.14, saturation: 0.78, brightness: 0.96),
    ]

    private func colorForId(_ id: String) -> Color {
        let topLevel = String(id.split(separator: ".").first ?? Substring(id))
        return Self.categoryColors[topLevel] ?? Color.gray
    }

    /// Ring sizes adapt as the user drills down.
    /// When descriptors are visible the outer ring expands to ~5× its default width,
    /// making every descriptor a large, comfortable tap target.
    private func radii(size: CGFloat) -> RingRadii {
        if expandedSubcategory != nil {
            // Descriptors visible — compress inner rings, maximise outer ring
            return RingRadii(
                innerStart: size * 0.13, innerEnd: size * 0.21,
                midStart:   size * 0.22, midEnd:   size * 0.32,
                outerStart: size * 0.34, outerEnd: size * 0.50,
                holeRadius: size * 0.12
            )
        } else {
            // Default / category-expanded layout
            return RingRadii(
                innerStart: size * 0.20, innerEnd: size * 0.35,
                midStart:   size * 0.36, midEnd:   size * 0.46,
                outerStart: size * 0.47, outerEnd: size * 0.50,
                holeRadius: size * 0.18
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r      = radii(size: size)

            ZStack {
                Canvas { ctx, canvasSize in
                    let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                    drawWheel(context: ctx, center: c, r: r)
                }

                centerOverlay(holeRadius: r.holeRadius)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(at: location, center: center, r: r)
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.28), value: expandedSubcategory?.id)
    }

    // MARK: - Center Overlay

    private func centerOverlay(holeRadius: CGFloat) -> some View {
        let activeColor: Color = {
            if let s = expandedSubcategory { return colorForId(s.id) }
            if let c = expandedCategory    { return colorForId(c.id) }
            return Color.primary
        }()

        return VStack(spacing: 3) {
            if let subcategory = expandedSubcategory {
                Text(subcategory.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(activeColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { expandedSubcategory = nil }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(activeColor.opacity(0.8))
                }
            } else if let category = expandedCategory {
                Text(category.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(activeColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { expandedCategory = nil }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(activeColor.opacity(0.8))
                }
            } else {
                Text("Tap to\nexplore")
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.muted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: holeRadius * 1.7, height: holeRadius * 1.7)
    }

    // MARK: - Drawing

    private func drawWheel(context: GraphicsContext, center: CGPoint, r: RingRadii) {
        let categories   = FlavorWheel.categories
        let gapDegrees   = 1.5

        if let category = expandedCategory {
            let catColor = colorForId(category.id)

            // ── Inner ring ────────────────────────────────────────────────
            let arcSpan = 360.0 / Double(categories.count)

            for (i, cat) in categories.enumerated() {
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg   = startDeg + arcSpan - gapDegrees
                let isActive = cat.id == category.id
                let color    = colorForId(cat.id)

                let path = arcSegmentPath(center: center, innerRadius: r.innerStart, outerRadius: r.innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path,   with: .color(color.opacity(isActive ? 0.80 : 0.18)))
                context.stroke(path, with: .color(color.opacity(isActive ? 1.00 : 0.35)),
                               lineWidth: isActive ? 1.5 : 0.5)

                let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (r.innerStart + r.innerEnd) / 2
                let pt        = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let textColor = Color(isActive ? .white : UIColor.systemGray2)
                let text = Text(cat.name)
                    .font(.system(size: r.innerFontSize, weight: isActive ? .bold : .regular))
                    .foregroundColor(textColor)
                context.draw(context.resolve(text), at: pt, anchor: .center)
            }

            // ── Middle ring — subcategories ───────────────────────────────
            let subcategories = category.children
            if !subcategories.isEmpty {
                let subArcSpan = 360.0 / Double(subcategories.count)
                for (j, sub) in subcategories.enumerated() {
                    let startDeg   = Double(j) * subArcSpan - 90 + gapDegrees / 2
                    let endDeg     = startDeg + subArcSpan - gapDegrees
                    let isExpanded = expandedSubcategory?.id == sub.id
                    let opacity: Double = isExpanded ? 0.78 : (j % 2 == 0 ? 0.38 : 0.54)

                    let path = arcSegmentPath(center: center, innerRadius: r.midStart, outerRadius: r.midEnd,
                                              startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                    context.fill(path,   with: .color(catColor.opacity(opacity)))
                    context.stroke(path, with: .color(catColor.opacity(0.85)), lineWidth: 1)

                    let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                    let midRadius = (r.midStart + r.midEnd) / 2
                    let pt        = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                    let text = Text(sub.name)
                        .font(.system(size: r.midFontSize, weight: isExpanded ? .bold : .medium))
                        .foregroundColor(.white)
                    context.draw(context.resolve(text), at: pt, anchor: .center)
                }
            }

            // ── Outer ring — descriptors of expanded subcategory ──────────
            if let subcategory = expandedSubcategory {
                let descriptors = subcategory.children
                if !descriptors.isEmpty {
                    let descArcSpan = 360.0 / Double(descriptors.count)
                    for (k, desc) in descriptors.enumerated() {
                        let startDeg   = Double(k) * descArcSpan - 90 + gapDegrees / 2
                        let endDeg     = startDeg + descArcSpan - gapDegrees
                        let isSelected = selectedFlavorIds.contains(desc.id)
                        let fillOpacity: Double = isSelected ? 1.0 : (k % 2 == 0 ? 0.22 : 0.36)

                        let path = arcSegmentPath(center: center, innerRadius: r.outerStart, outerRadius: r.outerEnd,
                                                  startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                        context.fill(path,   with: .color(catColor.opacity(fillOpacity)))
                        context.stroke(path, with: .color(catColor.opacity(isSelected ? 1.0 : 0.45)),
                               lineWidth: isSelected ? 2.5 : 0.5)

                        let midAngle   = Angle.degrees((startDeg + endDeg) / 2)
                        let midRadius  = (r.outerStart + r.outerEnd) / 2
                        let pt         = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                        let textColor: Color = isSelected ? .white : Color(UIColor.label).opacity(0.75)
                        let text = Text(desc.name)
                            .font(.system(size: r.outerFontSize, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(textColor)
                        context.draw(context.resolve(text), at: pt, anchor: .center)
                    }
                }
            }

        } else {
            // ── Default: all 9 categories ─────────────────────────────────
            let arcSpan = 360.0 / Double(categories.count)
            for (i, cat) in categories.enumerated() {
                let startDeg = Double(i) * arcSpan - 90 + gapDegrees / 2
                let endDeg   = startDeg + arcSpan - gapDegrees
                let catColor = colorForId(cat.id)

                let path = arcSegmentPath(center: center, innerRadius: r.innerStart, outerRadius: r.innerEnd,
                                          startAngle: .degrees(startDeg), endAngle: .degrees(endDeg))
                context.fill(path,   with: .color(catColor.opacity(0.72)))
                context.stroke(path, with: .color(catColor.opacity(0.95)), lineWidth: 1)

                let midAngle  = Angle.degrees((startDeg + endDeg) / 2)
                let midRadius = (r.innerStart + r.innerEnd) / 2
                let pt        = pointOnCircle(center: center, radius: midRadius, angle: midAngle)
                let text = Text(cat.name)
                    .font(.system(size: r.innerFontSize, weight: .semibold))
                    .foregroundColor(.white)
                context.draw(context.resolve(text), at: pt, anchor: .center)
            }
        }
    }

    // MARK: - Hit Testing

    private func handleTap(at point: CGPoint, center: CGPoint, r: RingRadii) {
        let dx     = point.x - center.x
        let dy     = point.y - center.y
        let radius = sqrt(dx * dx + dy * dy)
        let angle  = Angle(radians: atan2(dy, dx))

        // Center tap → navigate back
        if radius < r.innerStart {
            withAnimation(.easeInOut(duration: 0.25)) {
                if expandedSubcategory != nil { expandedSubcategory = nil }
                else                          { expandedCategory = nil }
            }
            return
        }

        let categories = FlavorWheel.categories

        if expandedCategory == nil {
            // Inner ring → select category
            guard radius >= r.innerStart && radius <= r.innerEnd else { return }
            let index = arcIndex(angle: angle, count: categories.count)
            if index < categories.count {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedCategory = categories[index]
                }
            }

        } else if let category = expandedCategory {
            // Inner ring → switch or collapse category
            if radius >= r.innerStart && radius <= r.innerEnd {
                let index = arcIndex(angle: angle, count: categories.count)
                if index < categories.count {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if categories[index].id == category.id {
                            expandedCategory    = nil
                            expandedSubcategory = nil
                        } else {
                            expandedCategory    = categories[index]
                            expandedSubcategory = nil
                        }
                    }
                }
                return
            }

            // Middle ring → select subcategory
            let subcategories = category.children
            if radius >= r.midStart && radius <= r.midEnd && !subcategories.isEmpty {
                let index = arcIndex(angle: angle, count: subcategories.count)
                if index < subcategories.count {
                    let tappedSub = subcategories[index]
                    if tappedSub.isLeaf {
                        toggle(id: tappedSub.id)
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedSubcategory = tappedSub
                        }
                    }
                }
                return
            }

            // Outer ring → toggle descriptor
            if let subcategory = expandedSubcategory {
                let descriptors = subcategory.children
                if radius >= r.outerStart && radius <= r.outerEnd && !descriptors.isEmpty {
                    let index = arcIndex(angle: angle, count: descriptors.count)
                    if index < descriptors.count {
                        toggle(id: descriptors[index].id)
                    }
                }
            }
        }
    }

    private func arcIndex(angle: Angle, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var degrees = angle.degrees + 90
        while degrees < 0   { degrees += 360 }
        while degrees >= 360 { degrees -= 360 }
        return min(Int(degrees / (360.0 / Double(count))), count - 1)
    }

    private func toggle(id: String) {
        if selectedFlavorIds.contains(id) { selectedFlavorIds.remove(id) }
        else                              { selectedFlavorIds.insert(id) }
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
