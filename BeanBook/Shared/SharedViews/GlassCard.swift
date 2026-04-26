import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var cornerRadius: CGFloat = Theme.cardRadius
    var tint: Color? = nil
    var padding: CGFloat = Theme.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceLow, in: .rect(cornerRadius: cornerRadius))
            .glassEffect(
                reduceTransparency
                    ? .identity
                    : .regular.tint((tint ?? Theme.primaryContainer).opacity(0.15)),
                in: .rect(cornerRadius: cornerRadius)
            )
            .shadow(
                color: Theme.cardShadowColor,
                radius: Theme.cardShadowRadius,
                y: Theme.cardShadowY
            )
    }
}

struct GlassInput<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var cornerRadius: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfaceBright, in: .rect(cornerRadius: cornerRadius))
            .glassEffect(
                reduceTransparency ? .identity : .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
