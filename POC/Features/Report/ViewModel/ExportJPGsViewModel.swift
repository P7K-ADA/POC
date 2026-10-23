//
//  ExportJPGsViewModel.swift
//  POC
//

import SwiftUI

@MainActor
final class ExportJPGsViewModel: ObservableObject {
    struct AlertState: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let dismissesSheet: Bool
    }

    let report: ReportData

    @Published private(set) var items: [ExportItem] = []
    @Published var selection = Set(ExportItem.Kind.allCases)
    @Published private(set) var isSaving = false
    @Published var alert: AlertState?

    var selectedCount: Int {
        items.filter { selection.contains($0.kind) }.count
    }

    init(report: ReportData) {
        self.report = report
    }

    func prepare() async {
        guard items.isEmpty else { return }

        do {
            items = try ReportExportService.render(report)
        } catch {
            alert = AlertState(
                title: "Couldn't prepare images",
                message: error.localizedDescription,
                dismissesSheet: true
            )
        }
    }

    func toggleSelection(for item: ExportItem) {
        if selection.contains(item.kind) {
            selection.remove(item.kind)
        } else {
            selection.insert(item.kind)
        }
    }

    func saveSelectedItems() async {
        let chosen = items.filter { selection.contains($0.kind) }
        guard !chosen.isEmpty, !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await ReportExportService.saveToPhotos(chosen)
            alert = AlertState(
                title: "Saved to Photos",
                message: String(chosen.count) + " image" + (chosen.count == 1 ? "" : "s") + " saved.",
                dismissesSheet: true
            )
        } catch {
            alert = AlertState(
                title: "Couldn't save",
                message: error.localizedDescription,
                dismissesSheet: false
            )
        }
    }

    func dismissAlert() {
        alert = nil
    }
}
