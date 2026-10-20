//
//  StartScanningButton.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//



import SwiftUI

struct StartScanningButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Start Scanning")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Color(white: 0.28),
                    in: Capsule()
                )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
