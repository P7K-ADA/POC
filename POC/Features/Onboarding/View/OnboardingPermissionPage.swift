//
//  OnboardingPermissionPage.swift
//  POC
//

import SwiftUI

struct OnboardingPermissionPage: View {
    let permission: OnboardingPermission
    let isAllowEnabled: Bool
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 200)

                Image(systemName: permission.systemImage)
                    .font(.system(size: 72))
                    .foregroundStyle(Color.gray)
            }

            Spacer().frame(height: 48)

            Text(permission.title)
                .font(.title3.weight(.bold))

            Text(permission.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            Button(action: onAllow) {
                Text("Allow")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(isAllowEnabled ? Color.accentColor : Color.gray)
                    )
            }
            .padding(.horizontal, 32)

            Button("Maybe later", action: onSkip)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 16)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPermissionPage(
        permission: .camera,
        isAllowEnabled: false,
        onAllow: {},
        onSkip: {}
    )
}
