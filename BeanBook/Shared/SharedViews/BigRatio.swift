import SwiftUI

/// Large serif `1:X.XX` display with ease-out count-up. Mirrors `C2BigRatio`.
struct BigRatio: View {
    let ratio: Double
    var size: CGFloat = 96
    var color: Color = Theme.ink
    var sub: String? = nil
    var alignment: HorizontalAlignment = .center

    @State private var displayRatio: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: alignment, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("1")
                    .font(.system(size: size, weight: .ultraLight, design: .serif))
                    .foregroundStyle(color)
                Text(":")
                    .font(.system(size: size * 0.58, weight: .ultraLight, design: .serif))
                    .foregroundStyle(Theme.ink3)
                Text(displayRatio.formatted(.number.precision(.fractionLength(2))))
                    .font(.system(size: size, weight: .ultraLight, design: .serif))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: displayRatio))
            }
            .kerning(-size * 0.04)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            if let sub {
                Eyebrow(sub)
                    .tracking(1.8)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
        .onAppear {
            if reduceMotion {
                displayRatio = ratio
            } else {
                withAnimation(.smooth(duration: 0.7)) { displayRatio = ratio }
            }
        }
        .onChange(of: ratio) { _, newValue in
            if reduceMotion {
                displayRatio = newValue
            } else {
                withAnimation(.snappy(duration: 0.35)) { displayRatio = newValue }
            }
        }
    }
}

/// Animated dose↔yield bar — accent share of the bar visualizes 1/(1+ratio).
struct RatioBar: View {
    let ratio: Double
    var height: CGFloat = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let dosePct = ratio > 0 ? 1.0 / (1.0 + ratio) : 0
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * dosePct)
                Rectangle()
                    .fill(Theme.ink4)
            }
            .clipShape(.rect(cornerRadius: height / 2))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: ratio)
        }
        .frame(height: height)
        .background(Theme.rule, in: .rect(cornerRadius: height / 2))
    }
}

private extension HorizontalAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }
}
