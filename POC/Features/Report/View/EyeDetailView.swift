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
            VStack(alignment: .leading, spacing: 16) {
                ReportHeaderView(report: report)

                Picker("Eye", selection: $side) {
                    Text(EyeSide.left.rawValue).tag(EyeSide.left)
                    Text(EyeSide.right.rawValue).tag(EyeSide.right)
                }
                .pickerStyle(.segmented)

                EyeDetailContent(eye: report.eye(side))
            }
            .padding()
        }
        .background(ReportPalette.page)
        .navigationTitle("Eye Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack { EyeDetailView(report: .sample, initialSide: .left) }
}
#endif
