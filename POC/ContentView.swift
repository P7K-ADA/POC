//
//  ContentView.swift
//  POC
//
//  Created by Carolyn Santana on 12/10/26.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScanView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
