import SwiftUI
import VisionKit

// MARK: - Scanner Sheet (Flow Container)

struct BagScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var recognizedTexts: [String] = []
    @State private var scanComplete = false
    @State private var parsedLabel: ParsedBagLabel?

    var body: some View {
        NavigationStack {
            Group {
                if scanComplete, let label = parsedLabel {
                    ScanResultReviewView(parsedLabel: label)
                } else {
                    BagScannerCameraView(recognizedTexts: $recognizedTexts)
                }
            }
            .navigationTitle(scanComplete ? "" : "Scan Bag Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !scanComplete {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(AppColors.primary)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done Scanning") {
                            let parsed = BagLabelParser.parse(recognizedTexts: recognizedTexts)
                            parsedLabel = parsed
                            scanComplete = true
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Camera View (UIViewControllerRepresentable)

struct BagScannerCameraView: UIViewControllerRepresentable {
    @Binding var recognizedTexts: [String]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedTexts: $recognizedTexts)
    }

    // MARK: Coordinator

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedTexts: [String]

        init(recognizedTexts: Binding<[String]>) {
            _recognizedTexts = recognizedTexts
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                switch item {
                case .text(let text):
                    let transcript = text.transcript
                    if !transcript.isEmpty && !recognizedTexts.contains(transcript) {
                        recognizedTexts.append(transcript)
                    }
                default:
                    break
                }
            }
        }
    }
}
