import SwiftUI

struct APIKeySection: View {
    @Bindable var model: AppModel

    var body: some View {
        Section {
            SecureField("sk-ant-api...", text: $model.apiKey)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Label("Anthropic API Key", systemImage: "key.fill")
        } footer: {
            Text("Stored securely in the iOS Keychain on this device only.")
        }
    }
}

#Preview {
    Form { APIKeySection(model: AppModel()) }
}
