import SwiftUI

/// Vertical method list — matches the C2 NewBrew step 1 layout.
struct MethodPicker: View {
    @Binding var selection: BrewMethod
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            ForEach(BrewMethod.allCases) { method in
                MethodRow(method: method, isSelected: selection == method) {
                    withMotion(Motion.control, reduceMotion: reduceMotion) { selection = method }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct MethodRow: View {
    let method: BrewMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HairRule()
                HStack(spacing: 14) {
                    Image(systemName: method.symbol)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.ink2)
                        .frame(width: 26)
                    Text(method.displayName)
                        .font(.system(size: 21,
                                      weight: isSelected ? .semibold : .regular,
                                      design: .serif))
                        .tracking(-0.3)
                        .foregroundStyle(isSelected ? Theme.accent : Theme.ink)
                    Spacer()
                    if isSelected {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 18)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(method.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
