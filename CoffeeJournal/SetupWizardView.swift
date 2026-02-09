import SwiftUI

struct SetupWizardView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Setup Wizard")
                .font(.title)
            Text("This is a placeholder for your onboarding flow.")
                .foregroundStyle(.secondary)
            Button("Finish Setup") {
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
