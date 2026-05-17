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
        InputView(model: model)
    }
}

#Preview {
    ContentView()
}
