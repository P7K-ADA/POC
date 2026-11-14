//
//  EyeDetailExpandedImageView.swift
//  POC
//

import SwiftUI

struct EyeDetailExpandedImageView: View {
    let eye: EyeReport
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = eye.segmentationReferenceImage ?? eye.image {
                    GeometryReader { geometry in
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)

                            if let mask = eye.segmentationMask,
                               let roiRect = eye.roiRectNormalized,
                               let overlay = SegmentationOverlay.makeImage(
                                   from: mask,
                                   width: eye.maskWidth,
                                   height: eye.maskHeight,
                                   canvasSize: image.size,
                                   roiRectNormalized: roiRect
                               ) {
                                Image(uiImage: overlay)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(
                                        width: geometry.size.width,
                                        height: geometry.size.height
                                    )
                            }
                        }
                    }
                } else {
                    Text("Foto tidak tersedia")
                        .foregroundStyle(.white)
                }
            }
            .navigationTitle(eye.side == .left ? "Mata Kiri (OS)" : "Mata Kanan (OD)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup", action: onDismiss)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
