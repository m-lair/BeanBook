import SwiftUI

struct StarRating: View {
    @Binding var rating: Int?
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = (rating == star) ? nil : star
                } label: {
                    Image(systemName: (rating ?? 0) >= star ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(
                            (rating ?? 0) >= star
                                ? Theme.primary
                                : Theme.onBackgroundVariant.opacity(0.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(star) out of \(maxRating)")
                .accessibilityAddTraits((rating ?? 0) >= star ? [.isButton, .isSelected] : .isButton)
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}
