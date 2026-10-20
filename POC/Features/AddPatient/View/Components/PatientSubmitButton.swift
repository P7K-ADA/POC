//
//  PatientSubmitButton.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//

import SwiftUI

struct PatientSubmitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Submit")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray, in: Capsule())
        }
        .padding()
    }
}

#Preview {
    PatientSubmitButton {}
        .background(Color(uiColor: .systemGroupedBackground))
}
