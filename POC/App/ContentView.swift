//
//  ContentView.swift
//  POC
//
//  Created by Carolyn Santana on 12/10/26.
//

import SwiftUI
 
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
 
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ScanView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
 
#Preview {
    ContentView()
}
 
