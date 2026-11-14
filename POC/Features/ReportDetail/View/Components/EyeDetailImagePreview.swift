//
//  EyeDetailImagePreview.swift
//  POC
//

import SwiftUI

struct EyeDetailImagePreview: View {
    let eye: EyeReport
    var onExpand: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SegmentationImageView(
                side: eye.side,
                image: eye.image,
                segmentationReferenceImage: eye.segmentationReferenceImage,
                segmentationMask: eye.segmentationMask,
                maskWidth: eye.maskWidth,
                maskHeight: eye.maskHeight,
                aspectRatio: Layout.reviewImageAspectRatio
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))

            Button(action: onExpand) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(14)
            .accessibilityLabel("Perbesar foto")
        }
    }
}
