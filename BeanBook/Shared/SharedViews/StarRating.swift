import SwiftUI

/// 5-circle rating control — replaces the old star UI with the C2 rating-dots pattern.
/// Same API as before so existing call sites (`@Binding var rating: Int?`) keep working.
struct StarRating: View {
    @Binding var rating: Int?
    var maxRating: Int = 5
    var dotSize: CGFloat = 18

    var body: some View {
        HStack(spacing: dotSize - 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    rating = (rating == star) ? nil : star
                } label: {
                    Circle()
                        .fill((rating ?? 0) >= star ? Theme.accent : Theme.rule)
                        .frame(width: dotSize, height: dotSize)
                        .animation(.easeOut(duration: 0.2), value: rating)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(star) out of \(maxRating)")
                .accessibilityAddTraits((rating ?? 0) >= star ? [.isButton, .isSelected] : .isButton)
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}

/// Read-only mini variant — used in list rows.
struct RatingDots: View {
    let value: Int
    var size: CGFloat = 6
    var maxRating: Int = 5

    var body: some View {
        HStack(spacing: size - 1) {
            ForEach(1...maxRating, id: \.self) { i in
                Circle()
                    .fill(i <= value ? Theme.accent : Theme.rule)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(value) of \(maxRating)")
    }
}
