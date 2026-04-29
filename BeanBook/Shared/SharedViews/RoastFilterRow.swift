import SwiftUI

/// Horizontally-scrolling filter chips for `RoastLevel`. Each chip shows the
/// roast color as a leading dot, so the row doubles as a visual scale legend.
/// Selection is `nil` for "All".
struct RoastFilterRow: View {
    @Binding var selection: RoastLevel?
    var showsLegendCaption: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsLegendCaption {
                Eyebrow("Roast · tap to filter", color: Theme.ink3)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    RoastChip(
                        label: "All",
                        swatch: nil,
                        selected: selection == nil
                    ) { selection = nil }

                    ForEach(RoastLevel.allCases) { level in
                        RoastChip(
                            label: level.displayName,
                            swatch: level.swatch,
                            selected: selection == level
                        ) {
                            selection = (selection == level) ? nil : level
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct RoastChip: View {
    let label: String
    let swatch: Color?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let swatch {
                    Circle()
                        .fill(swatch)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(selected ? 0.55 : 0), lineWidth: 0.5)
                        )
                }
                Text(label)
                    .font(Theme.body(11, weight: .semibold))
                    .tracking(0.6)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? .white : Theme.ink2)
            .background(selected ? Theme.accent : Theme.card, in: .capsule)
            .overlay(Capsule().stroke(selected ? .clear : Theme.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
