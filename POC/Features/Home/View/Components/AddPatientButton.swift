//
//  AddPatientButton.swift
//  POC
//
//  Created by Carolyn Santana on 20/10/26.
//

import SwiftUI

struct AddPatientButton: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.quaternary, in: Circle())
            .accessibilityLabel("Add Patient")
    }
}

#Preview {
    AddPatientButton()
}

