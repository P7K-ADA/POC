//
//  ContentView.swift
//  POC
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingOnboarding = true

    var body: some View {
        Group {
            if isShowingOnboarding {
                OnboardingView {
                    isShowingOnboarding = false
                }
            } else {
                ScanView()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
