import SwiftUI

/// A "Bags 12 of 15" row used in Settings to show free-tier usage.
/// Highlights the count when within 3 of the cap.
struct QuotaUsageRow: View {
    let label: String
    let count: Int
    let quota: Int

    private var nearLimit: Bool {
        (quota - count) <= 3
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(count) of \(quota)")
                    .font(Theme.body(14, weight: nearLimit ? .semibold : .regular))
                    .foregroundStyle(nearLimit ? Theme.error : Theme.ink2)
                    .monospacedDigit()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Theme.rule).padding(.leading, 24)
        }
    }
}
