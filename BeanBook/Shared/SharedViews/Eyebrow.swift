import SwiftUI

/// Tiny uppercase label — recurring micro-typography pattern from the C2 design.
/// Mirrors `C2Eyebrow` (11pt, tracked +2.4, weight 600, ink3 by default).
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.ink3

    init(_ text: String, color: Color = Theme.ink3) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.body(11, weight: .semibold))
            .tracking(2.4)
            .foregroundStyle(color)
    }
}
