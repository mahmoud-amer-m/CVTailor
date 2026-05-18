//
//  CVTailorApp.swift
//  CVTailor
//
//  Created by Mahmoud Amer on 17.05.26.
//

import SwiftUI
import SwiftData

@main
struct CVTailorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TailoredCVRecord.self)
    }
}
