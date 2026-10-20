//
//  PatientRegistrationHeader.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct PatientRegistrationHeader: View {
    let onBack: () -> Void
    let onFAQ: () -> Void

    var body: some View {
        HStack {
            if #available(iOS 26.0, *) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                        .frame(width: 44, height: 44)
                        .background(.background, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .glassEffect(.regular, in: .circle)
                .accessibilityLabel("Back")
            } else {
                // Fallback on earlier versions
            }

            Spacer()

            Text("Patient Registration")
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            if #available(iOS 26.0, *) {
                Button(action: onFAQ) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.background, in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .glassEffect(.regular, in: .circle)
                .accessibilityLabel("FAQ")
            } else {
                // Fallback on earlier versions
            }
        }
        .foregroundStyle(.primary)
        .padding()
    }
}

#Preview {
    PatientRegistrationHeader(
        onBack: {},
        onFAQ: {}
    )
    .background(Color(uiColor: .systemGroupedBackground))
}
