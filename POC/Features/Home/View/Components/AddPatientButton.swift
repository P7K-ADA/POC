
import SwiftUI

struct AddPatientButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 74, height: 74)
                .background(Color(uiColor: .systemGray5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Patient")
    }
}

#Preview {
    AddPatientButton {}
        .padding()
}
