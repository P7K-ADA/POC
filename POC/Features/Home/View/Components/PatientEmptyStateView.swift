//
//  PatientEmptyStateView.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//


import SwiftUI

struct PatientEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person")
                .font(.system(size: 32))
                .frame(width: 80, height: 80)
                .background(.quaternary, in: Circle())

            Text("No patients yet")
                .font(.title2.bold())

            Text("Add your first patient to start managing their records.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    PatientEmptyStateView()
}
