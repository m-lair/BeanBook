import SwiftUI

/// Horizontal-scrolling strip of recent brews. Tap a card to hot-start a new brew
/// with that brew's values prefilled (lands on Step 2 in `NewBrewSheet`).
struct RecentShotsStrip: View {
    let brews: [Brew]
    let onTap: (Brew) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow("Recent shots")
                Spacer()
                Text("Tap to brew again")
                    .font(Theme.body(11))
                    .tracking(0.4)
                    .foregroundStyle(Theme.ink3)
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(brews) { brew in
                        Button {
                            onTap(brew)
                        } label: {
                            RecentShotCard(brew: brew)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 24)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

private struct RecentShotCard: View {
    let brew: Brew

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: brew.method.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.ink3)
                Text(brew.method.displayName)
                    .font(Theme.body(11, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Theme.ink3)
            }

            Text(brew.formattedRatio)
                .font(.system(size: 22, weight: .medium, design: .serif))
                .tracking(-0.5)
                .foregroundStyle(Theme.ink)
                .monospacedDigit()

            HStack(spacing: 8) {
                Text(brew.formattedTime)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.ink2)
                    .monospacedDigit()
                if let r = brew.rating, r > 0 {
                    RatingDots(value: r, size: 4)
                }
            }

            Spacer(minLength: 0)

            Text(brew.bag?.displayTitle ?? "No bag")
                .font(Theme.body(11))
                .foregroundStyle(Theme.ink3)
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 150, height: 130, alignment: .topLeading)
        .background(Theme.card, in: .rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.rule, lineWidth: 0.5)
        )
        .contentShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Brew this shot again")
    }

    private var accessibilityDescription: String {
        var parts: [String] = [brew.method.displayName, brew.formattedRatio, brew.formattedTime]
        if let bag = brew.bag {
            parts.append(bag.displayTitle)
        }
        if let r = brew.rating, r > 0 {
            parts.append("\(r) of 5 stars")
        }
        return parts.joined(separator: ", ")
    }
}
