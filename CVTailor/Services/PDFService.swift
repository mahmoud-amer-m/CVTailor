import PDFKit
import SwiftUI
import CoreText
import UIKit
import UniformTypeIdentifiers

struct PDFService {
    static func extractText(from data: Data) -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        return document.string
    }

    static func generatePDF(from text: String, matchingPDF originalData: Data? = nil) -> Data {
        let (pageSize, bodyFont) = styleFromOriginal(originalData)
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
            .font: bodyFont,
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

    // Extracts page size and dominant body font from the first page of a PDF.
    // Font size is determined by finding the most frequent size in the page's text.
    private static func styleFromOriginal(_ data: Data?) -> (pageSize: CGRect, bodyFont: UIFont) {
        let fallbackSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        let fallbackFont = UIFont.systemFont(ofSize: 11)

        guard let data,
              let doc = PDFDocument(data: data),
              let page = doc.page(at: 0) else {
            return (fallbackSize, fallbackFont)
        }

        let pageSize = page.bounds(for: .mediaBox)

        guard let selection = page.selection(for: page.bounds(for: .mediaBox)),
              let attrString = selection.attributedString,
              attrString.length > 0 else {
            return (pageSize, fallbackFont)
        }

        var sizeFrequency: [CGFloat: Int] = [:]
        var sizeToFontName: [CGFloat: String] = [:]

        attrString.enumerateAttribute(.font, in: NSRange(location: 0, length: attrString.length)) { value, _, _ in
            guard let font = value as? UIFont else { return }
            let size = font.pointSize
            sizeFrequency[size, default: 0] += 1
            if sizeToFontName[size] == nil {
                sizeToFontName[size] = font.fontName
            }
        }

        let bodySize = sizeFrequency.max(by: { $0.value < $1.value })?.key ?? 11
        let bodyFont = sizeToFontName[bodySize].flatMap { UIFont(name: $0, size: bodySize) }
                    ?? UIFont.systemFont(ofSize: bodySize)

        return (pageSize, bodyFont)
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
