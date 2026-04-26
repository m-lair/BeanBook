import SwiftUI

/// Eyebrow-style section header (uppercase, tracked) — matches the C2 rhythm.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(title)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
