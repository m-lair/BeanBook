import SwiftUI

/// Plain card surface — no longer glass-frosted under the Ritual redesign.
/// Kept as a transitional shim so existing call sites keep compiling.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Theme.cardRadius
    var tint: Color? = nil
    var padding: CGFloat = Theme.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.rule, lineWidth: 0.5)
            )
    }
}

struct GlassInput<Content: View>: View {
    var cornerRadius: CGFloat = 12
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.rule, lineWidth: 0.5)
            )
    }
}
