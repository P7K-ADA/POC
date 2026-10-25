//
//  OnboardingView.swift
//  POC
//
//  Created by Harley Ganisson on 25/10/26.
//


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
                onAllow: { Task { await viewModel.allow() } },
                onSkip: viewModel.skip
            )
            .id(viewModel.currentIndex)
            .transition(.opacity)
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { onFinish() }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}