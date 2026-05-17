import PDFKit
import CoreText
import UIKit

// Captures the three typographic roles found in the original PDF.
struct CVStyleGuide {
    let pageSize: CGRect
    let nameFont: UIFont
    let nameColor: UIColor
    let headerFont: UIFont
    let headerColor: UIColor
    let bodyFont: UIFont
    let bodyColor: UIColor

    static let `default` = CVStyleGuide(
        pageSize: CGRect(x: 0, y: 0, width: 612, height: 792),
        nameFont: .boldSystemFont(ofSize: 20),
        nameColor: .black,
        headerFont: .boldSystemFont(ofSize: 13),
        headerColor: .black,
        bodyFont: .systemFont(ofSize: 11),
        bodyColor: .black
    )
}

struct PDFService {

    // MARK: - Text extraction

    static func extractText(from data: Data) -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        return document.string
    }

    // MARK: - Style guide extraction

    static func extractStyleGuide(from data: Data?) -> CVStyleGuide {
        guard let data,
              let doc = PDFDocument(data: data),
              let page = doc.page(at: 0) else { return .default }

        let pageSize = page.bounds(for: .mediaBox)

        guard let selection = page.selection(for: page.bounds(for: .mediaBox)),
              let attrString = selection.attributedString,
              attrString.length > 0 else {
            return CVStyleGuide(
                pageSize: pageSize,
                nameFont: CVStyleGuide.default.nameFont,
                nameColor: CVStyleGuide.default.nameColor,
                headerFont: CVStyleGuide.default.headerFont,
                headerColor: CVStyleGuide.default.headerColor,
                bodyFont: CVStyleGuide.default.bodyFont,
                bodyColor: CVStyleGuide.default.bodyColor
            )
        }

        // Collect all distinct runs: font size → (charCount, UIFont, UIColor)
        var sizeInfo: [CGFloat: (count: Int, font: UIFont, color: UIColor)] = [:]

        attrString.enumerateAttributes(
            in: NSRange(location: 0, length: attrString.length)
        ) { attrs, range, _ in
            guard let font = attrs[.font] as? UIFont else { return }
            let color = (attrs[.foregroundColor] as? UIColor) ?? .black
            let size = font.pointSize
            if let existing = sizeInfo[size] {
                sizeInfo[size] = (existing.count + range.length, font, existing.color)
            } else {
                sizeInfo[size] = (range.length, font, color)
            }
        }

        let bySize = sizeInfo.sorted { $0.key > $1.key }   // largest first
        let byFreq = sizeInfo.sorted { $0.value.count > $1.value.count } // most common first

        // Body  = most frequent size (the bulk of the document)
        let bodyEntry   = byFreq.first
        let bodySize    = bodyEntry?.key ?? 11
        let bodyFont    = resolveFont(bodyEntry?.value.font)
        let bodyColor   = resolveColor(bodyEntry?.value.color)

        // Name  = largest font in the document
        let nameEntry   = bySize.first
        let nameFont    = resolveFont(nameEntry?.value.font, fallbackBold: true)
        let nameColor   = resolveColor(nameEntry?.value.color)

        // Header = largest size that is strictly smaller than the name
        //          and larger than body, otherwise fall back to bold body size
        let headerEntry = bySize.first { $0.key < (nameEntry?.key ?? 0) && $0.key > bodySize }
                       ?? bySize.dropFirst().first
        let headerFont  = resolveFont(headerEntry?.value.font, fallbackBold: true,
                                      fallbackSize: bodySize + 1)
        let headerColor = resolveColor(headerEntry?.value.color)

        return CVStyleGuide(
            pageSize: pageSize,
            nameFont: nameFont,
            nameColor: nameColor,
            headerFont: headerFont,
            headerColor: headerColor,
            bodyFont: bodyFont,
            bodyColor: bodyColor
        )
    }

    // MARK: - PDF generation

    static func generatePDF(from text: String, styleGuide: CVStyleGuide = .default) -> Data {
        let pageSize  = styleGuide.pageSize
        let margin: CGFloat = 50
        let textRect  = CGRect(
            x: margin, y: margin,
            width: pageSize.width  - 2 * margin,
            height: pageSize.height - 2 * margin
        )

        let attrString = buildAttributedString(from: text, styleGuide: styleGuide)
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
                    path, nil
                )
                CTFrameDraw(frame, ctx)

                // setURL(_:for:) works in current user space (CTM-aware), so call it
                // here while still inside the flipped context so the rects from
                // CTFrameGetLineOrigins align correctly.
                for (url, rect) in collectLinkRects(from: frame) {
                    ctx.setURL(url as CFURL, for: rect)
                }

                let visible = CTFrameGetVisibleStringRange(frame)
                currentLocation = visible.location + visible.length
            } while currentLocation < attrString.length
        }
    }

    // Walks every CTRun in the frame looking for an "NSLink" attribute.
    // Returns rects in the flipped coordinate system (origin = top-left).
    private static func collectLinkRects(from frame: CTFrame) -> [(url: URL, rect: CGRect)] {
        var results: [(URL, CGRect)] = []

        let lines = CTFrameGetLines(frame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)

        for (i, line) in lines.enumerated() {
            for run in (CTLineGetGlyphRuns(line) as! [CTRun]) {
                let attrs = CTRunGetAttributes(run) as NSDictionary
                // NSAttributedString.Key.link.rawValue == "NSLink"
                let linkValue = attrs["NSLink"]
                guard let url: URL = {
                    if let u = linkValue as? URL    { return u }
                    if let s = linkValue as? String { return URL(string: s) }
                    return nil
                }() else { continue }

                var ascent: CGFloat = 0, descent: CGFloat = 0
                let width = CTRunGetTypographicBounds(
                    run, CFRange(location: 0, length: 0), &ascent, &descent, nil
                )
                let xOffset = CTLineGetOffsetForStringIndex(
                    line, CTRunGetStringRange(run).location, nil
                )

                // In the flipped system, y increases downward.
                // The glyph top edge is (baseline - ascent), bottom edge is (baseline + descent).
                let rect = CGRect(
                    x: origins[i].x + xOffset,
                    y: origins[i].y - ascent,
                    width: CGFloat(width),
                    height: ascent + descent
                )
                results.append((url, rect))
            }
        }
        return results
    }

    // MARK: - Attributed string builder

    private static func buildAttributedString(
        from text: String,
        styleGuide: CVStyleGuide
    ) -> NSAttributedString {
        let lines  = text.components(separatedBy: "\n")
        let result = NSMutableAttributedString()
        var seenFirstNonEmpty = false

        let bodyParagraph = makeParagraphStyle(spacing: 2)
        let headerParagraph = makeParagraphStyle(spacing: 6, spacingBefore: 8)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            let font: UIFont
            let color: UIColor
            let paragraph: NSMutableParagraphStyle

            if trimmed.isEmpty {
                font      = styleGuide.bodyFont
                color     = styleGuide.bodyColor
                paragraph = bodyParagraph
            } else if !seenFirstNonEmpty {
                seenFirstNonEmpty = true
                font      = styleGuide.nameFont
                color     = styleGuide.nameColor
                paragraph = makeParagraphStyle(spacing: 4)
            } else if isHeaderLine(trimmed, index: index, lines: lines) {
                font      = styleGuide.headerFont
                color     = styleGuide.headerColor
                paragraph = headerParagraph
            } else {
                font      = styleGuide.bodyFont
                color     = styleGuide.bodyColor
                paragraph = bodyParagraph
            }

            result.append(NSAttributedString(
                string: line + "\n",
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
            ))
        }

        // Detect URLs and apply .link + underline so they become clickable in the PDF.
        if let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) {
            let fullRange = NSRange(location: 0, length: result.length)
            for match in detector.matches(in: result.string, range: fullRange) {
                guard let url = match.url else { continue }
                result.addAttributes([
                    .link: url,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: match.range)
            }
        }

        return result
    }

    // MARK: - Line classification

    // A line is treated as a section header if it is ALL CAPS (common CV convention)
    // or if it is a short line surrounded by blank lines on both sides.
    private static func isHeaderLine(_ trimmed: String, index: Int, lines: [String]) -> Bool {
        guard !trimmed.hasPrefix("•"),
              !trimmed.hasPrefix("-"),
              !trimmed.hasPrefix("*") else { return false }

        let hasLetters = trimmed.rangeOfCharacter(from: .letters) != nil

        // ALL CAPS heuristic
        if hasLetters && trimmed == trimmed.uppercased() && trimmed.count < 60 {
            return true
        }

        // Isolated short line (blank line above and below)
        let prevBlank = index == 0 ||
            lines[index - 1].trimmingCharacters(in: .whitespaces).isEmpty
        let nextBlank = index >= lines.count - 1 ||
            lines[index + 1].trimmingCharacters(in: .whitespaces).isEmpty
        if prevBlank && nextBlank && trimmed.count < 40 {
            return true
        }

        return false
    }

    // MARK: - Helpers

    private static func makeParagraphStyle(
        spacing: CGFloat,
        spacingBefore: CGFloat = 0
    ) -> NSMutableParagraphStyle {
        let s = NSMutableParagraphStyle()
        s.lineSpacing       = 2
        s.paragraphSpacing  = spacing
        s.paragraphSpacingBefore = spacingBefore
        return s
    }

    // Maps a UIFont from PDFKit (may have a subsetted name like "ABCDEF+Helvetica-Bold")
    // to a usable system font, preserving weight and size.
    private static func resolveFont(
        _ pdfFont: UIFont?,
        fallbackBold: Bool = false,
        fallbackSize: CGFloat = 11
    ) -> UIFont {
        guard let pdfFont else {
            return fallbackBold
                ? .boldSystemFont(ofSize: fallbackSize)
                : .systemFont(ofSize: fallbackSize)
        }

        let size = pdfFont.pointSize
        var name = pdfFont.fontName

        // Strip PDF subset prefix (e.g. "ABCDEF+FontName" → "FontName")
        if let plusRange = name.range(of: "+") {
            name = String(name[name.index(after: plusRange.lowerBound)...])
        }

        if let resolved = UIFont(name: name, size: size) {
            return resolved
        }

        // Fall back preserving bold/italic traits
        let isBold   = pdfFont.fontDescriptor.symbolicTraits.contains(.traitBold)
        let isItalic = pdfFont.fontDescriptor.symbolicTraits.contains(.traitItalic)

        if isBold && isItalic,
           let descriptor = UIFont.boldSystemFont(ofSize: size)
               .fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return isBold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
    }

    // Converts the extracted color to RGBA to ensure it is renderable on a white background.
    private static func resolveColor(_ color: UIColor?) -> UIColor {
        guard let color else { return .black }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return .black }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

