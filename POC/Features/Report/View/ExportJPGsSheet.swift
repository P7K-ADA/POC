//
//  ExportJPGsSheet.swift
//  POC
//
//  Created by Harley Ganisson on 20/10/26.
//


import SwiftUI

struct ExportJPGsSheet: View {
    let report: ReportData

    @Environment(\.dismiss) private var dismiss
    @State private var items: [ExportItem] = []
    @State private var selection = Set(ExportItem.Kind.allCases)
    @State private var isSaving = false
    @State private var alert: ExportAlert?

    private struct ExportAlert {
        let title: String
        let message: String
        let dismissesSheet: Bool
    }

    private var selectedCount: Int {
        items.filter { selection.contains($0.kind) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Export JPGs")
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
            }

            ReportHeaderView(report: report)

            if items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        row(item)
                    }
                }
            }

            Spacer(minLength: 0)

            Text("Patient name, capture date, and the AI disclaimer appear on all exported report images. Saved images are identifiable patient data and will appear in your Photos library.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                save()
            } label: {
                HStack {
                    if isSaving { ProgressView() }
                    Label(
                        "Save \(selectedCount) image\(selectedCount == 1 ? "" : "s") to Photos",
                        systemImage: "square.and.arrow.down"
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCount == 0 || isSaving)
        }
        .padding(20)
        .task {
            do {
                items = try ReportExportService.render(report)
            } catch {
                alert = ExportAlert(
                    title: "Couldn't prepare images",
                    message: error.localizedDescription,
                    dismissesSheet: true
                )
            }
        }
        .alert(
            alert?.title ?? "",
            isPresented: Binding(
                get: { alert != nil },
                set: { if !$0 { alert = nil } }
            ),
            presenting: alert
        ) { current in
            Button("OK") {
                if current.dismissesSheet { dismiss() }
            }
        } message: { current in
            Text(current.message)
        }
    }

    private func row(_ item: ExportItem) -> some View {
        let isSelected = selection.contains(item.kind)

        return Button {
            if isSelected {
                selection.remove(item.kind)
            } else {
                selection.insert(item.kind)
            }
        } label: {
            HStack(spacing: 12) {
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text(item.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? ReportPalette.accent : .secondary)
            }
            .padding(10)
            .background(ReportPalette.page)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let chosen = items.filter { selection.contains($0.kind) }
        guard !chosen.isEmpty else { return }

        isSaving = true
        Task {
            do {
                try await ReportExportService.saveToPhotos(chosen)
                alert = ExportAlert(
                    title: "Saved to Photos",
                    message: "\(chosen.count) image\(chosen.count == 1 ? "" : "s") saved.",
                    dismissesSheet: true
                )
            } catch {
                alert = ExportAlert(
                    title: "Couldn't save",
                    message: error.localizedDescription,
                    dismissesSheet: false
                )
            }
            isSaving = false
        }
    }
}

#if DEBUG
#Preview {
    ExportJPGsSheet(report: .sample)
}
#endif