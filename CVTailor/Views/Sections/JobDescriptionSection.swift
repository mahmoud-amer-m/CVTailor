import SwiftUI

struct JobDescriptionSection: View {
    @Bindable var model: AppModel

    var body: some View {
        Section {
            TextEditor(text: $model.jobDescription)
                .frame(minHeight: 130)
        } header: {
            Label("Job Description", systemImage: "briefcase.fill")
        }
    }
}

#Preview {
    Form { JobDescriptionSection(model: AppModel()) }
}
