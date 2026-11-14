import SwiftUI
import UIKit

struct SegmentationImageView: View {
    let side: EyeSide
    let image: UIImage?
    let segmentationReferenceImage: UIImage?
    let segmentationMask: [UInt8]?
    let maskWidth: Int
    let maskHeight: Int
    var roiRectNormalized: CGRect? = nil
    var aspectRatio: CGFloat = 3.0 / 4.0

    private var alignedOverlay: UIImage? {
        guard let image,
              let mask = segmentationMask,
              let roi = roiRectNormalized,
              let cgImage = image.cgImage else { return nil }

        return SegmentationOverlay.makeImage(
            from: mask,
            width: maskWidth,
            height: maskHeight,
            canvasSize: CGSize(width: cgImage.width, height: cgImage.height),
            roiRectNormalized: roi
        )
    }

    var body: some View {
        Group {
            if let image {
                GeometryReader { geometry in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()

                        if let alignedOverlay {
                            Image(uiImage: alignedOverlay)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        }
                    }
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()
                .allowsHitTesting(false)
            } else {
                Color.black
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 4) {
                            Text(side.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("No Image")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
