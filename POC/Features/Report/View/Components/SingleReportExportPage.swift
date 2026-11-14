import SwiftUI

struct SingleReportExportPage: View {
    let report: ReportData

    private let pageWidth: CGFloat = 700

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                eyePhotoCell(eye: report.left)
                eyePhotoCell(eye: report.right)
            }
            .frame(width: pageWidth)
            .background(Color.white)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text("AI DISCLAIMER")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.black)

                Text("\(ReportCopy.cdrExplainer) \(ReportCopy.aiDisclaimer)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.86, green: 0.86, blue: 0.86))
        }
        .frame(width: pageWidth)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private func eyePhotoCell(eye: EyeReport) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let image = eye.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    if let mask = eye.segmentationMask,
                       let roi = eye.roiRectNormalized,
                       let cgImage = image.cgImage,
                       let overlay = SegmentationOverlay.makeImage(
                        from: mask,
                        width: eye.maskWidth,
                        height: eye.maskHeight,
                        canvasSize: CGSize(width: cgImage.width, height: cgImage.height),
                        roiRectNormalized: roi
                       ) {
                        Image(uiImage: overlay)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                } else {
                    Color(white: 0.94)
                    Text("No Image")
                        .font(.headline)
                        .foregroundStyle(.gray)
                }

                Text("CDR : \(eye.cdrText)")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(16)
                    .shadow(color: .black.opacity(0.85), radius: 4, x: 2, y: 2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipped()
    }
}
