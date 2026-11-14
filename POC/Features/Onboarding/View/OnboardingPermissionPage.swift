//
//  OnboardingPermissionPage.swift
//  POC
//

import SwiftUI

struct OnboardingPermissionPage: View {
    let permission: OnboardingPermission
    let isAllowEnabled: Bool
    let onAllow: () -> Void
    let onSkipNFCAttachment: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                title: permission.title,
                message: permission.message
            )

            OnboardingIllustration()

            Color.clear
                .frame(height: Layout.paginationAreaHeight)

            VStack(spacing: 12) {
                AppButton(
                    title: permission == .camera ? "Next" : "Allow",
                    tint: buttonTint,
                    width: Layout.buttonWidth,
                    height: Layout.buttonHeight,
                    accessibilityLabel: permission == .camera
                        ? "Continue after attaching the optical lens."
                        : "Allow permission.",
                    action: onAllow
                )

                if permission == .camera {
                    Button("Lewati pemasangan lensa untuk sekarang", action: onSkipNFCAttachment)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.labelSecondary)
                        .accessibilityHint("Melanjutkan onboarding tanpa memeriksa lampiran NFC.")
                }
            }
            .padding(.bottom, Layout.onboardingBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private var buttonTint: Color {
        isAllowEnabled ? AppColors.accentBlue : AppColors.fillsSecondary
    }
}

#Preview("NFC belum terdeteksi") {
    OnboardingPermissionPage(
        permission: .camera,
        isAllowEnabled: false,
        onAllow: {},
        onSkipNFCAttachment: {}
    )
}

#Preview("NFC terdeteksi") {
    OnboardingPermissionPage(
        permission: .camera,
        isAllowEnabled: true,
        onAllow: {},
        onSkipNFCAttachment: {}
    )
}
