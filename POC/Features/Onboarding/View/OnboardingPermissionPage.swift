//
//  OnboardingPermissionPage.swift
//  POC
//
//  Created by Harley Ganisson on 25/10/26.
//


//
//  OnboardingPermissionPage.swift
//  POC
//
//  Lo-fi layout: icon circle, title, description, Allow button, Maybe later.
//

import SwiftUI

struct OnboardingPermissionPage: View {
    let permission: OnboardingPermission
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon placeholder
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 200)

                Image(systemName: permission.systemImage)
                    .font(.system(size: 72))
                    .foregroundStyle(Color.gray)
            }
            .accessibilityHidden(true)

            Spacer().frame(height: 48)

            Text(permission.title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .accessibilityAddTraits(.isHeader)

            Text(permission.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            Button(action: onAllow) {
                Text("Allow")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.gray))
            }
            .accessibilityLabel("Allow permission to access camera.")
            .padding(.horizontal, 32)

            Button("Maybe later", action: onSkip)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .padding(.vertical, 20)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
            
                .accessibilityLabel("Deny permission to access camera.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPermissionPage(permission: .camera, onAllow: {}, onSkip: {})
}
