import Foundation
import Observation

@Observable
class AppModel {
    var jobDescription: String = ""
    var cvText: String = ""
    var tailoredCV: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func tailorCV(apiKey: String) async {
        guard !jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !cvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please provide both a job description and your CV."
            return
        }

        isLoading = true
        errorMessage = nil
        tailoredCV = ""

        do {
            tailoredCV = try await AnthropicService.tailorCV(
                jobDescription: jobDescription,
                cv: cvText,
                apiKey: apiKey
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
