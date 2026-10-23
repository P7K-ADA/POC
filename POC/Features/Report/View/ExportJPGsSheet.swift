//
//  ExportJPGsSheet.swift
//  POC
//

import SwiftUI

struct ExportJPGsSheet: View {
    @StateObject private var viewModel: ExportJPGsViewModel
    @Environment(\.dismiss) private var dismiss

    init(report: ReportData) {
        _viewModel = StateObject(
            wrappedValue: ExportJPGsViewModel(report: report)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExportSheetHeader(onClose: dismiss.callAsFunction)

            ReportHeaderView(capturedLine: viewModel.report.capturedLine)

            if viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        ExportJPGRow(
                            item: item,
                            isSelected: viewModel.selection.contains(item.kind),
                            onToggle: {
                                viewModel.toggleSelection(for: item)
                            }
                        )
                    }
                }
            }

            Spacer(minLength: 0)

            Text("The screening label, capture date, and AI disclaimer appear on all exported report images.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await viewModel.saveSelectedItems()
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                    }

                    Text(saveButtonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedCount == 0 || viewModel.isSaving)
        }
        .padding(20)
        .task {
            await viewModel.prepare()
        }
        .alert(
            viewModel.alert?.title ?? "",
            isPresented: alertBinding
        ) {
            Button("OK") {
                let dismissesSheet = viewModel.alert?.dismissesSheet == true
                viewModel.dismissAlert()

                if dismissesSheet {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alert?.message ?? "")
        }
    }

    private var saveButtonTitle: String {
        let suffix = viewModel.selectedCount == 1 ? "" : "s"
        return "Save " + String(viewModel.selectedCount) + " image" + suffix + " to Photos"
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissAlert()
                }
            }
        )
    }
}

private struct ExportSheetHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text("Export JPGs")
                .font(.title2.bold())

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close")
        }
    }
}

private struct ExportJPGRow: View {
    let item: ExportItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
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
}

#if DEBUG
#Preview {
    ExportJPGsSheet(report: .sample)
}
#endif
