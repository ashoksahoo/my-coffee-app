import SwiftUI

struct FlavorTagFlowView: View {
    let tags: [(id: String, name: String, isCustom: Bool)]
    let onToggle: (String) -> Void
    let onRemoveCustom: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.id) { tag in
                FlavorTagChipView(
                    name: tag.name,
                    isSelected: true,
                    onTap: { onToggle(tag.id) },
                    onRemove: tag.isCustom ? { onRemoveCustom(tag.id) } : nil
                )
            }
        }
    }
}
