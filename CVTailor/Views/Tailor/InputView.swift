import SwiftUI
import SwiftData

struct InputView: View {
    @Bindable var model: AppModel
    @Environment(\.modelContext) private var modelContext

    @State private var showingClearConfirm = false
    @State private var navigateToResult = false

    private var canTailor: Bool {
        !model.apiKey.isEmpty && !model.jobDescription.isEmpty &&
        !model.cvText.isEmpty && !model.isLoading
    }

    var body: some View {
        Form {
            APIKeySection(model: model)
            JobDescriptionSection(model: model)
            CVInputSection(model: model)
            actionSection
        }
        .navigationTitle("CV Tailor")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(model.jobDescription.isEmpty && model.cvText.isEmpty)
            }
        }
        .confirmationDialog(
            "Clear all fields?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                model.jobDescription = ""
                model.cvText = ""
                model.originalPDFData = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the job description and CV. Your API key will not be affected.")
        }
        .navigationDestination(isPresented: $navigateToResult) {
            if let record = model.recentRecord {
                ResultView(record: record)
            }
        }
        .overlay {
            if model.isLoading {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.4)
                            .tint(.white)
                        Text("Tailoring your CV…")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .allowsHitTesting(!model.isLoading)
        .alert(
            model.errorTitle ?? "Error",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("Try Again") { runTailor() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var actionSection: some View {
        Section {
            Button { runTailor() } label: {
                HStack {
                    Spacer()
                    if model.isLoading {
                        ProgressView().padding(.trailing, 6)
                    } else {
                        Image(systemName: "wand.and.sparkles").padding(.trailing, 4)
                    }
                    Text(model.isLoading ? "Tailoring…" : "Tailor My CV")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!canTailor)
        }
    }

    private func runTailor() {
        Task {
            await model.tailorCV(modelContext: modelContext)
            if model.errorMessage == nil && model.recentRecord != nil {
                navigateToResult = true
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TailoredCVRecord.self, configurations: config)
    NavigationStack {
        InputView(model: AppModel())
    }
    .modelContainer(container)
}
