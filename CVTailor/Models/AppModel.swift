import Foundation
import Observation

@Observable
class AppModel {
    var jobDescription: String = ""
    var cvText: String = ""
    var tailoredCV: String = ""
    var isLoading: Bool = false
    var errorTitle: String? = nil
    var errorMessage: String? = nil

    func tailorCV(apiKey: String) async {
        guard !jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !cvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorTitle = "Missing Input"
            errorMessage = "Please provide both a job description and your CV."
            return
        }

        isLoading = true
        errorTitle = nil
        errorMessage = nil
        tailoredCV = ""

        do {
            tailoredCV = try await AnthropicService.tailorCV(
                jobDescription: jobDescription,
                cv: cvText,
                apiKey: apiKey
            )
        } catch let err as AnthropicError {
            errorTitle = err.errorTitle
            errorMessage = err.localizedDescription
        } catch {
            errorTitle = "Error"
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
