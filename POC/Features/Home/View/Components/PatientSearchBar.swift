
import SwiftUI

struct PatientSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search Patient", text: $text)
                .font(.system(size: 17))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(Color(uiColor: .systemGray5))
        .clipShape(Capsule())
    }
}

#Preview {
    PatientSearchBar(text: .constant(""))
        .padding()
}
