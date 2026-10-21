//
//  ContentView.swift
//  POC
//
//  Created by Carolyn Santana on 12/10/26.
//


import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(
                onReturnHome: {
                    navigationPath = NavigationPath()
                }
            )
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
