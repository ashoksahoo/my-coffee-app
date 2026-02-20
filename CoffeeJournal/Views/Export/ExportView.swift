import SwiftUI
import SwiftData
import PostHog

struct ExportView: View {
    @Query(sort: \BrewLog.createdAt, order: .reverse) private var brews: [BrewLog]

    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var exportType: String = ""
    @State private var showShareSheet = false

    var body: some View {
        List {
            Section {
                Text("\(brews.count) brews in your journal")
                    .foregroundStyle(.secondary)
            }

            Section("Export Format") {
                Button {
                    exportPDF()
                } label: {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
                .disabled(brews.isEmpty || isExporting)

                Button {
                    exportCSV()
                } label: {
                    Label("Export as CSV", systemImage: "tablecells")
                }
                .disabled(brews.isEmpty || isExporting)
            }
        }
        .navigationTitle("Export")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                if exportType == "pdf" {
                    ShareLink(item: ExportedPDF(url: url), preview: SharePreview("Coffee Journal", image: Image(systemName: "doc.richtext")))
                } else {
                    ShareLink(item: ExportedCSV(url: url), preview: SharePreview("Coffee Journal", image: Image(systemName: "tablecells")))
                }
            }
        }
    }

    private func exportPDF() {
        isExporting = true
        // PostHog: Track export initiated
        PostHogSDK.shared.capture("export_initiated", properties: [
            "format": "pdf",
            "brew_count": brews.count,
        ])
        Task { @MainActor in
            exportURL = PDFExporter.generateJournal(brews: brews)
            isExporting = false
            if exportURL != nil {
                exportType = "pdf"
                showShareSheet = true
            }
        }
    }

    private func exportCSV() {
        isExporting = true
        // PostHog: Track export initiated
        PostHogSDK.shared.capture("export_initiated", properties: [
            "format": "csv",
            "brew_count": brews.count,
        ])
        Task { @MainActor in
            exportURL = CSVExporter.generateCSV(brews: brews)
            isExporting = false
            if exportURL != nil {
                exportType = "csv"
                showShareSheet = true
            }
        }
    }
}
