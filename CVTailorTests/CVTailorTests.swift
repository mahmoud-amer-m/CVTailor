import XCTest
import SwiftData
@testable import CVTailor

final class PDFServiceTests: XCTestCase {

    func testGeneratePDFReturnsNonEmptyData() {
        let data = PDFService.generatePDF(from: "John Doe\nSoftware Engineer")
        XCTAssertFalse(data.isEmpty)
    }

    func testGeneratePDFHasPDFMagicBytes() {
        let data = PDFService.generatePDF(from: "Test")
        XCTAssertEqual(data.prefix(4), Data("%PDF".utf8))
    }

    func testExtractTextFromInvalidDataReturnsNil() {
        XCTAssertNil(PDFService.extractText(from: Data([0x00, 0x01, 0x02])))
    }

    func testExtractTextFromGeneratedPDFSucceeds() {
        let pdfData = PDFService.generatePDF(from: "Hello World")
        XCTAssertNotNil(PDFService.extractText(from: pdfData))
    }

    func testExtractStyleGuideFromNilReturnsDefault() {
        let guide = PDFService.extractStyleGuide(from: nil)
        XCTAssertEqual(guide.pageSize, CVStyleGuide.default.pageSize)
    }

    func testExtractStyleGuideFromInvalidDataReturnsDefault() {
        let guide = PDFService.extractStyleGuide(from: Data([0x00, 0x01]))
        XCTAssertEqual(guide.pageSize, CVStyleGuide.default.pageSize)
    }

    func testExtractStyleGuideFromGeneratedPDFHasPositiveFontSizes() {
        let pdf = PDFService.generatePDF(from: "John Doe\n\nEXPERIENCE\nBuilt apps")
        let guide = PDFService.extractStyleGuide(from: pdf)
        XCTAssertGreaterThan(guide.bodyFont.pointSize, 0)
        XCTAssertGreaterThan(guide.nameFont.pointSize, 0)
        XCTAssertGreaterThan(guide.headerFont.pointSize, 0)
    }

    func testNameFontIsAtLeastAsLargeAsBodyFont() {
        let pdf = PDFService.generatePDF(from: "John Doe\n\nEXPERIENCE\nBuilt apps")
        let guide = PDFService.extractStyleGuide(from: pdf)
        XCTAssertGreaterThanOrEqual(guide.nameFont.pointSize, guide.bodyFont.pointSize)
    }

    func testDefaultStyleGuidePageSize() {
        let guide = CVStyleGuide.default
        XCTAssertEqual(guide.pageSize.width, 612)
        XCTAssertEqual(guide.pageSize.height, 792)
    }
}

final class AnthropicErrorTests: XCTestCase {

    func testErrorTitles() {
        XCTAssertEqual(AnthropicError.invalidAPIKey.errorTitle,   "Invalid API Key")
        XCTAssertEqual(AnthropicError.permissionDenied.errorTitle, "Permission Denied")
        XCTAssertEqual(AnthropicError.rateLimited.errorTitle,     "Rate Limit Reached")
        XCTAssertEqual(AnthropicError.serverOverloaded.errorTitle, "Server Overloaded")
        XCTAssertEqual(AnthropicError.serverError(503).errorTitle, "Server Error")
        XCTAssertEqual(AnthropicError.networkError("x").errorTitle, "Network Error")
        XCTAssertEqual(AnthropicError.emptyResponse.errorTitle,   "Unexpected Response")
        XCTAssertEqual(AnthropicError.unexpectedResponse.errorTitle, "Unexpected Response")
        XCTAssertEqual(AnthropicError.invalidRequest("x").errorTitle, "Invalid Request")
    }

    func testErrorDescriptionsAreNonNil() {
        let errors: [AnthropicError] = [
            .invalidAPIKey, .permissionDenied, .rateLimited, .serverOverloaded,
            .serverError(500), .networkError("err"), .emptyResponse,
            .unexpectedResponse, .invalidRequest("msg")
        ]
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) had nil description")
        }
    }

    func testServerErrorIncludesStatusCode() {
        XCTAssertTrue(AnthropicError.serverError(503).errorDescription?.contains("503") == true)
    }

    func testInvalidRequestIncludesMessage() {
        XCTAssertTrue(AnthropicError.invalidRequest("bad param").errorDescription?.contains("bad param") == true)
    }

    func testNetworkErrorIncludesMessage() {
        XCTAssertTrue(AnthropicError.networkError("connection refused").errorDescription?.contains("connection refused") == true)
    }
}

final class AppModelTests: XCTestCase {

    private func makeModelContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TailoredCVRecord.self, configurations: config)
        return container.mainContext
    }

    @MainActor
    func testTailorCVWithEmptyJobDescriptionSetsError() async throws {
        let model = AppModel()
        model.jobDescription = ""
        model.cvText = "Some CV content"
        await model.tailorCV(modelContext: try makeModelContext())
        XCTAssertEqual(model.errorTitle, "Missing Input")
        XCTAssertNotNil(model.errorMessage)
    }

    @MainActor
    func testTailorCVWithEmptyCVSetsError() async throws {
        let model = AppModel()
        model.jobDescription = "Some job description"
        model.cvText = ""
        await model.tailorCV(modelContext: try makeModelContext())
        XCTAssertEqual(model.errorTitle, "Missing Input")
    }

    @MainActor
    func testTailorCVWithWhitespaceOnlyInputsSetsError() async throws {
        let model = AppModel()
        model.jobDescription = "   \t\n"
        model.cvText = "   \t\n"
        await model.tailorCV(modelContext: try makeModelContext())
        XCTAssertEqual(model.errorTitle, "Missing Input")
    }

    @MainActor
    func testInitialStateHasNoErrors() {
        let model = AppModel()
        XCTAssertNil(model.recentRecord)
        XCTAssertFalse(model.isLoading)
        XCTAssertNil(model.errorTitle)
        XCTAssertNil(model.errorMessage)
        XCTAssertNil(model.originalPDFData)
    }
}
