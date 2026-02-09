import SwiftUI

struct BrewTimerView: View {
    @Bindable var viewModel: BrewLogViewModel
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Large monospaced time display
            Text(formattedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(AppColors.primary)

            // Control buttons
            HStack(spacing: AppSpacing.lg) {
                switch viewModel.timerState {
                case .idle:
                    Button("Start") { viewModel.startTimer() }
                        .monochromeButtonStyle()
                case .running:
                    Button("Pause") { viewModel.pauseTimer() }
                        .monochromeButtonStyle()
                    Button("Stop") { viewModel.stopTimer() }
                        .monochromeButtonStyle()
                case .paused:
                    Button("Resume") { viewModel.resumeTimer() }
                        .monochromeButtonStyle()
                    Button("Stop") { viewModel.stopTimer() }
                        .monochromeButtonStyle()
                case .stopped:
                    Button("Reset") { viewModel.resetTimer() }
                        .monochromeButtonStyle()
                }
            }

            // Step Guide toggle -- only show when timer is idle or stopped
            if viewModel.selectedMethod != nil {
                if viewModel.timerState == .idle || viewModel.timerState == .stopped {
                    Toggle("Step Guide", isOn: $viewModel.guidanceEnabled)
                        .font(AppTypography.body)
                }
            }
        }
        .onReceive(timer) { _ in
            viewModel.updateTimer()
        }
    }

    // MARK: - Formatted Time (M:SS.t)

    private var formattedTime: String {
        let total = Int(viewModel.elapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        let tenths = Int((viewModel.elapsedSeconds - Double(total)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}
