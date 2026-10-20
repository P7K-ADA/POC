
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
                .background(.primary, in: Capsule())
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview {
    PatientSubmitButton {}
        .background(Color(uiColor: .systemGroupedBackground))
}
