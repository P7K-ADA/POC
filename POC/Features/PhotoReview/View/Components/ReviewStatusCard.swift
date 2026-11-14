import SwiftUI

struct ReviewStatusCard: View {
    let analysisErrorMessage: String?
    let isAnalyzing: Bool
    let qualityWarnings: [String]

    private var isError: Bool {
        analysisErrorMessage != nil
    }

    private var title: String {
        if isAnalyzing {
            return "Menganalisis Foto"
        }

        if isError {
            return "Foto mungkin tidak terbaca"
        }

        return "Kualitas Gambar Baik"
    }

    private var subtitle: String {
        if isAnalyzing {
            return "Memeriksa kualitas gambar dan melakukan segmentasi optic disc dan optic cup."
        }

        if let analysisErrorMessage {
            return analysisErrorMessage
        }

        if !qualityWarnings.isEmpty {
            return "Analisis selesai dengan beberapa catatan kualitas."
        }

        return "Foto berhasil diproses dan siap digunakan."
    }

    private var tint: Color {
        if isAnalyzing {
            return AppColors.normal
        }

        return isError ? AppColors.accentRed : AppColors.normal
    }

    private var systemName: String {
        if isAnalyzing {
            return "hourglass"
        }

        return isError ? "exclamationmark" : "checkmark"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(
                alignment: .top,
                spacing: Layout.reviewStatusContentSpacing
            ) {
                ReviewStatusIcon(
                    systemName: systemName,
                    tint: tint
                )

                VStack(
                    alignment: .leading,
                    spacing: Layout.reviewStatusTextSpacing
                ) {
                    Text(title)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(AppColors.labelPrimary)

                    Text(subtitle)
                        .font(.footnote.weight(.regular))
                        .foregroundStyle(AppColors.labelPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if !isAnalyzing && !isError && !qualityWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(qualityWarnings, id: \.self) { warning in
                        Label(
                            warning,
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(AppColors.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(Layout.reviewStatusCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.white,
            in: RoundedRectangle(
                cornerRadius: Layout.reviewStatusCardCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

private struct ReviewStatusIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        RoundedRectangle(
            cornerRadius: Layout.reviewStatusIconCornerRadius,
            style: .continuous
        )
        .fill(tint.opacity(0.12))
        .frame(
            width: Layout.reviewStatusIconSize,
            height: Layout.reviewStatusIconSize
        )
        .overlay {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
        }
        .accessibilityHidden(true)
    }
}
