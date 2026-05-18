---
name: project-architecture
description: CVTailor app architecture after SwiftData migration — models, navigation, data flow
metadata:
  type: project
---

SwiftData-backed iOS app for tailoring CVs with Claude AI.

**Models:**
- `TailoredCVRecord` (`@Model`) — persists jobDescription, cvText, tailoredCV, originalPDFData (Data?), createdAt. Located at `CVTailor/Models/TailoredCVRecord.swift`.
- `AppModel` (`@Observable`) — session state: apiKey (Keychain), jobDescription, cvText, originalPDFData, recentRecord (TailoredCVRecord?), isLoading, error fields. `tailorCV(modelContext:) async` inserts a new record on success.

**Navigation:** TabView with two NavigationStacks
- Tab 1 "Tailor": InputView → ResultView (after generation)
- Tab 2 "History": HistoryView (@Query, newest first) → ResultView (from history)

**ResultView** takes `record: TailoredCVRecord` (not raw strings).

**Why:** Added CV history feature so users can revisit past tailored CVs.
**How to apply:** When adding new features, extend TailoredCVRecord or add new @Model classes. ModelContainer is set up in CVTailorApp with `.modelContainer(for: TailoredCVRecord.self)`.
