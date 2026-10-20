//
//  PatientDetailHeader.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct PatientDetailHeader: View {
    let onBack: () -> Void
    let onFAQ: () -> Void

    var body: some View {
        HStack {
            glassButton(
                symbol: "chevron.left",
                label: "Back",
                action: onBack
            )

            Spacer()

            Text("Patient Details")
                .font(.title2.bold())
                .lineLimit(1)

            Spacer()

            glassButton(
                symbol: "questionmark",
                label: "FAQ",
                action: onFAQ
            )
        }
        .foregroundStyle(.primary)
        .padding()
    }

    @ViewBuilder
    private func glassButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.title3.weight(.medium))
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .circle)
            .accessibilityLabel(label)
        } else {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.title3.weight(.medium))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        }
    }
}
