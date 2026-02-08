import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String = "Get Started"

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button(actionLabel, action: action)
                    .monochromeButtonStyle()
            }
        }
    }
}
