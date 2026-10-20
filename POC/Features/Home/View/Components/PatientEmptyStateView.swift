
import SwiftUI

struct PatientEmptyStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 92, height: 92)
                .background(Color(uiColor: .systemGray5))
                .clipShape(Circle())

            Text("No patients yet")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(.primary)

            Text(
                "Add your first patient to start managing\n" +
                "their records and appointments."
            )
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    PatientEmptyStateView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
}
