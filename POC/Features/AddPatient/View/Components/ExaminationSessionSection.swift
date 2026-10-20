//
//  ExaminationSessionSection.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct ExaminationSessionSection: View {
    var body: some View {
        Section {
            LabeledContent("Date & Time") {
                Text(
                    Date.now,
                    format: .dateTime
                        .day()
                        .month(.abbreviated)
                        .year()
                )
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Examination Session")
        }
    }
}

#Preview {
    Form {
        ExaminationSessionSection()
    }
    .formStyle(.grouped)
}
