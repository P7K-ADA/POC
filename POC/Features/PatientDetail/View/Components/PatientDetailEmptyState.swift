//
//  PatientDetailEmptyState.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct PatientDetailEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No scans yet")
                .font(.title3.bold())

            Text("Add your patient's first fundus imaging.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
