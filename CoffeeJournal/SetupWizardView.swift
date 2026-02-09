import SwiftUI

struct SetupWizardView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Setup Wizard")
                .font(.largeTitle)
                .bold()
            Text("This is a placeholder setup flow. Tap the button below to complete setup.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Complete Setup") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    SetupWizardView(onComplete: {})
}
