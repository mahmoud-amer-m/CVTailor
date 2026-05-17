import SwiftUI

struct ResultView: View {
    let tailoredCV: String

    private var exportPDF: ExportablePDF {
        ExportablePDF(data: PDFService.generatePDF(from: tailoredCV))
    }

    private var exportTXT: ExportableTXT {
        ExportableTXT(text: tailoredCV)
    }

    var body: some View {
        ScrollView {
            Text(tailoredCV)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .font(.body)
        }
        .navigationTitle("Tailored CV")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(
                    item: exportPDF,
                    preview: SharePreview(
                        "Tailored_CV.pdf",
                        image: Image(systemName: "doc.richtext")
                    )
                ) {
                    Label("Export PDF", systemImage: "doc.richtext")
                }

                ShareLink(
                    item: exportTXT,
                    preview: SharePreview(
                        "Tailored_CV.txt",
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Label("Export TXT", systemImage: "doc.text")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ResultView(tailoredCV: "John Doe\nSoftware Engineer\n\nExperience:\n• Built scalable iOS apps\n• Led cross-functional teams")
    }
}
