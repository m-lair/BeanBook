import SwiftUI

/// Recurring "label left, value right, hairline rule" row from the C2 detail screens.
struct RuleRow<Trailing: View>: View {
    let label: String
    var verticalPadding: CGFloat = 15
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink2)
                Spacer()
                trailing()
            }
            .padding(.vertical, verticalPadding)
            Rectangle()
                .fill(Theme.rule)
                .frame(height: 0.5)
        }
    }
}

extension RuleRow where Trailing == Text {
    init(_ label: String, value: String, verticalPadding: CGFloat = 15) {
        self.label = label
        self.verticalPadding = verticalPadding
        self.trailing = {
            Text(value)
                .font(Theme.body(14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Hairline horizontal rule.
struct HairRule: View {
    var color: Color = Theme.rule
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.5)
    }
}
