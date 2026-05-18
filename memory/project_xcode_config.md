---
name: project-xcode-config
description: Xcode project uses PBXFileSystemSynchronizedRootGroup — new Swift files auto-included, no pbxproj edits needed
metadata:
  type: project
---

The `.xcodeproj` uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 feature). New Swift files created anywhere inside the `CVTailor/` or `CVTailorTests/` directories are automatically picked up by Xcode — no need to add them manually via "Add Files to project" or edit `project.pbxproj`.

**Why:** Confirmed by inspecting project.pbxproj — it only has two PBXFileSystemSynchronizedRootGroup entries (CVTailor and CVTailorTests), no individual PBXFileReference entries for Swift files.
**How to apply:** Just create new .swift files in the right directory and they compile. SourceKit LSP running outside Xcode will show false "Cannot find X in scope" errors for cross-file symbols — these are expected and not real compilation errors.
