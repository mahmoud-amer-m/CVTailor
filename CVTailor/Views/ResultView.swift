import SwiftUI

struct ResultView: View {
    let tailoredCV: String
    let originalPDFData: Data?

    @State private var cachedPDFData: Data = Data()

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
                    item: ExportablePDF(data: cachedPDFData),
                    preview: SharePreview(
                        "Tailored_CV.pdf",
                        image: Image(systemName: "doc.richtext")
                    )
                ) {
                    Label("Export PDF", systemImage: "doc.richtext")
                }

                ShareLink(
                    item: ExportableTXT(text: tailoredCV),
                    preview: SharePreview(
                        "Tailored_CV.txt",
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Label("Export TXT", systemImage: "doc.text")
                }
            }
        }
        .task {
            let styleGuide = PDFService.extractStyleGuide(from: originalPDFData)
            cachedPDFData = PDFService.generatePDF(from: tailoredCV, styleGuide: styleGuide)
        }
    }
}

#Preview {
    NavigationStack {
        ResultView(
            tailoredCV: "John Doe\nSoftware Engineer\n\nExperience:\n• Built scalable iOS apps\n• Led cross-functional teams",
            originalPDFData: nil
        )
    }
}
