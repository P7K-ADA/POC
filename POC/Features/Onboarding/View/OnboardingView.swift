//
//  OnboardingView.swift
//  POC
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            OnboardingPermissionPage(
                permission: viewModel.currentPage,
                isAllowEnabled: viewModel.canAllowCurrentPermission,
                onAllow: { Task { await viewModel.allow() } },
                onSkip: viewModel.skip
            )
            .id(viewModel.currentIndex)
            .transition(.opacity)
        }
        .onAppear {
            viewModel.startNFCScanning()
        }
        .onDisappear {
            viewModel.stopNFCScanning()
        }
        .alert("Please attach frame", isPresented: $viewModel.showsNFCInstruction) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Attach the NTAG213 frame to the back of your iPhone, then tap Allow again.")
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished {
                onFinish()
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
