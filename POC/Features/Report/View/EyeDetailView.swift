//
//  EyeDetailView.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//



import SwiftUI

struct EyeDetailView: View {
    let report: ReportData

    @State private var side: EyeSide

    init(report: ReportData, initialSide: EyeSide) {
        self.report = report
        _side = State(initialValue: initialSide)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                ReportHeaderView(capturedLine: report.capturedLine)

                // Eye selector
                HStack(spacing: 8) {
                    eyeButton(.left)
                    eyeButton(.right)
                }

                // Selected eye details
                EyeDetailContent(eye: report.eye(side))
            }
            .padding()
        }
        .background(ReportPalette.page)
        .navigationTitle("Eye Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func eyeButton(_ eye: EyeSide) -> some View {
        let isSelected = side == eye

        return Button {
            side = eye
        } label: {
            Text(eye.rawValue)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    isSelected ? ReportPalette.accent : Color.white
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? ReportPalette.accent : Color.gray.opacity(0.25),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Shows the \(eye.rawValue.lowercased()) eye report.")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EyeDetailView(report: .sample, initialSide: .left)
    }
}
#endif
