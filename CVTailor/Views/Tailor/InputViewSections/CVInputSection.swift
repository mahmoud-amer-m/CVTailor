import SwiftUI
import UniformTypeIdentifiers

struct CVInputSection: View {
    @Bindable var model: AppModel

    @State private var cvMode: CVMode = .text
    @State private var showingFilePicker = false

    private enum CVMode: String, CaseIterable, Identifiable {
        case text = "Type / Paste"
        case pdf  = "Import PDF"
        var id: Self { self }
    }

    var body: some View {
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
                        model.cvText.isEmpty
                            ? "Select PDF File"
                            : "PDF loaded — tap to replace",
                        systemImage: model.cvText.isEmpty
                            ? "doc.badge.plus"
                            : "checkmark.circle.fill"
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
        // Reset to text mode whenever cvText is cleared (e.g. from the clear button).
        .onChange(of: model.cvText) { _, new in
            if new.isEmpty { cvMode = .text }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf]
        ) { result in
            importPDF(result)
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
            model.originalPDFData = data

        case .failure(let error):
            model.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    Form { CVInputSection(model: AppModel()) }
}
