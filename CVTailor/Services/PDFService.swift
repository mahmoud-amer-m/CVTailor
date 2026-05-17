import PDFKit
import CoreText
import UIKit
import UniformTypeIdentifiers

struct PDFService {
    static func extractText(from data: Data) -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        return document.string
    }

    static func generatePDF(from text: String) -> Data {
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 50
        let textRect = CGRect(
            x: margin, y: margin,
            width: pageSize.width - 2 * margin,
            height: pageSize.height - 2 * margin
        )

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.paragraphSpacing = 6

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black,
            .paragraphStyle: style
        ]

        let attrString = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        var currentLocation = 0

        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        return renderer.pdfData { context in
            repeat {
                context.beginPage()
                let ctx = context.cgContext
                ctx.saveGState()
                ctx.translateBy(x: 0, y: pageSize.height)
                ctx.scaleBy(x: 1, y: -1)

                let path = CGMutablePath()
                path.addRect(textRect)

                let frame = CTFramesetterCreateFrame(
                    framesetter,
                    CFRange(location: currentLocation, length: 0),
                    path,
                    nil
                )
                CTFrameDraw(frame, ctx)
                ctx.restoreGState()

                let visible = CTFrameGetVisibleStringRange(frame)
                currentLocation = visible.location + visible.length
            } while currentLocation < attrString.length
        }
    }
}

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
