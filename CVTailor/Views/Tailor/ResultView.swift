import SwiftUI
import SwiftData

struct ResultView: View {
    let record: TailoredCVRecord

    @State private var cachedPDFData: Data = Data()

    var body: some View {
        ScrollView {
            Text(record.tailoredCV)
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
                    item: ExportableTXT(text: record.tailoredCV),
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
            let styleGuide = PDFService.extractStyleGuide(from: record.originalPDFData)
            cachedPDFData = PDFService.generatePDF(from: record.tailoredCV, styleGuide: styleGuide)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TailoredCVRecord.self, configurations: config)
    let record = TailoredCVRecord(
        jobDescription: "Software Engineer at Stripe",
        cvText: "John Doe...",
        tailoredCV: "John Doe\nSoftware Engineer\n\nExperience:\n• Built scalable iOS apps\n• Led cross-functional teams",
        originalPDFData: nil
    )
    NavigationStack {
        ResultView(record: record)
    }
    .modelContainer(container)
}
