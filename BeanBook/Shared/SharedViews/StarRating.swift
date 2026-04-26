import SwiftUI

struct StarRating: View {
    @Binding var rating: Int?
    var max: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...max, id: \.self) { star in
                Button {
                    if rating == star { rating = nil }
                    else { rating = star }
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
                .sensoryFeedback(.selection, trigger: rating)
            }
        }
    }
}
