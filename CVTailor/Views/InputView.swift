import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct InputView: View {
    @Bindable var model: AppModel
    @AppStorage("anthropicAPIKey") private var apiKey = ""

    @State private var showingFilePicker = false
    @State private var cvMode: CVMode = .text
    @State private var navigateToResult = false

    private enum CVMode: String, CaseIterable, Identifiable {
        case text = "Type / Paste"
        case pdf = "Import PDF"
        var id: Self { self }
    }

    private var canTailor: Bool {
        !apiKey.isEmpty && !model.jobDescription.isEmpty && !model.cvText.isEmpty && !model.isLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                jobDescriptionSection
                cvSection
                actionSection
            }
            .navigationTitle("CV Tailor")
            .navigationDestination(isPresented: $navigateToResult) {
                ResultView(tailoredCV: model.tailoredCV)
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.pdf]
            ) { result in
                importPDF(result)
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.errorMessage = nil } }
                )
            ) {
                Button("OK") { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var apiKeySection: some View {
        Section {
            SecureField("sk-ant-api...", text: $apiKey)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Label("Anthropic API Key", systemImage: "key.fill")
        } footer: {
            Text("Stored in UserDefaults on this device only.")
        }
    }

    private var jobDescriptionSection: some View {
        Section {
            TextEditor(text: $model.jobDescription)
                .frame(minHeight: 130)
        } header: {
            Label("Job Description", systemImage: "briefcase.fill")
        }
    }

    private var cvSection: some View {
        Section {
            Picker("Input method", selection: $cvMode) {
                ForEach(CVMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if cvMode == .text {
                TextEditor(text: $model.cvText)
                    .frame(minHeight: 150)
            } else {
                Button(action: { showingFilePicker = true }) {
                    Label(
                        model.cvText.isEmpty ? "Select PDF File" : "PDF loaded — tap to replace",
                        systemImage: model.cvText.isEmpty ? "doc.badge.plus" : "checkmark.circle.fill"
                    )
                }
                .foregroundStyle(model.cvText.isEmpty ? Color.accentColor : Color.green)

                if !model.cvText.isEmpty {
                    Text("\(model.cvText.count) characters extracted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Your CV", systemImage: "person.text.rectangle.fill")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                Task {
                    await model.tailorCV(apiKey: apiKey)
                    if model.errorMessage == nil && !model.tailoredCV.isEmpty {
                        navigateToResult = true
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if model.isLoading {
                        ProgressView()
                            .padding(.trailing, 6)
                    } else {
                        Image(systemName: "wand.and.sparkles")
                            .padding(.trailing, 4)
                    }
                    Text(model.isLoading ? "Tailoring…" : "Tailor My CV")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!canTailor)
        }
    }

    private func importPDF(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url),
                  let text = PDFService.extractText(from: data),
                  !text.isEmpty else {
                model.errorMessage = "Could not extract text from this PDF. The file may be scanned or image-based."
                return
            }

            model.cvText = text

        case .failure(let error):
            model.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    InputView(model: AppModel())
}
