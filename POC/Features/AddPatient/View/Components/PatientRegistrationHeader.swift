
import SwiftUI

struct PatientRegistrationHeader: View {
    let onBack: () -> Void
    let onFAQ: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
                    .frame(width: 44, height: 44)
                    .background(.background, in: Circle())
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("Patient Registration")
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Button(action: onFAQ) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.background, in: Circle())
            }
            .accessibilityLabel("FAQ")
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
