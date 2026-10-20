//
//  ScreeningSessionCard.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct ScreeningSessionCard: View {
    let session: ScreeningSession
    let onPreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                EyeResultThumbnail(eye: session.leftEye)
                EyeResultThumbnail(eye: session.rightEye)
            }

            HStack(alignment: .bottom) {
                Text(
                    session.examDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Preview", action: onPreview)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.secondary)
            }
        }
        .padding()
        .background(
            .background,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}
