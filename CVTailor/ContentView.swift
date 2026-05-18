//
//  ContentView.swift
//  CVTailor
//
//  Created by Mahmoud Amer on 17.05.26.
//

import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()

    var body: some View {
        TabView {
            NavigationStack {
                InputView(model: model)
            }
            .tabItem {
                Label("Tailor", systemImage: "wand.and.stars")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
    }
}

#Preview {
    ContentView()
}
