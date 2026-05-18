import SwiftData
import Foundation

@Model
final class TailoredCVRecord {
    var cvTitle: String
    var createdAt: Date
    var jobDescription: String
    var cvText: String
    var tailoredCV: String
    var originalPDFData: Data?

    init(jobDescription: String, cvText: String, tailoredCV: String, originalPDFData: Data?) {
        let now = Date()
        self.createdAt = now
        self.cvTitle = "Tailored_\(now)"
        self.jobDescription = jobDescription
        self.cvText = cvText
        self.tailoredCV = tailoredCV
        self.originalPDFData = originalPDFData
    }
}
