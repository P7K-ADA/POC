//
//  ReportViewModel.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//

import SwiftUI

@MainActor
final class ReportViewModel: ObservableObject {
    let report: ReportData
    @Published var showingExport = false

    init(report: ReportData) {
        self.report = report
    }
}
