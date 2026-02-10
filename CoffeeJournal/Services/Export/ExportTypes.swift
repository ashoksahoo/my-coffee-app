import UniformTypeIdentifiers
import CoreTransferable

struct ExportedPDF: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { pdf in
            SentTransferredFile(pdf.url)
        }
    }
}

struct ExportedCSV: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            SentTransferredFile(csv.url)
        }
    }
}
