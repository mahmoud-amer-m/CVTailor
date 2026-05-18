import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TailoredCVRecord.createdAt, order: .reverse) var records: [TailoredCVRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(records) { record in
                NavigationLink {
                    ResultView(record: record)
                } label: {
                    HistoryRowView(record: record)
                }
            }
            .onDelete { offsets in
                for i in offsets {
                    modelContext.delete(records[i])
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            EditButton()
        }
        .overlay {
            if records.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock",
                    description: Text("Your tailored CVs will appear here")
                )
            }
        }
    }
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TailoredCVRecord.self, configurations: config)
    NavigationStack {
        HistoryView()
    }
    .modelContainer(container)
}
