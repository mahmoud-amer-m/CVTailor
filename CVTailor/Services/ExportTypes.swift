import SwiftUI
import UniformTypeIdentifiers

struct ExportablePDF: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { item in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Tailored_CV.pdf")
            try item.data.write(to: url)
            return SentTransferredFile(url)
        }
    }
}

struct ExportableTXT: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { item in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Tailored_CV.txt")
            try item.text.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
