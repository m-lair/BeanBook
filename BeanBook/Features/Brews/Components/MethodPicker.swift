import SwiftUI

struct MethodPicker: View {
    @Binding var selection: BrewMethod

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(BrewMethod.allCases) { method in
                    MethodChip(method: method, isSelected: selection == method) {
                        withAnimation(.snappy) { selection = method }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct MethodChip: View {
    let method: BrewMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: method.symbol)
                    .font(.title3)
                Text(method.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 84, height: 76)
            .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(Theme.onBackground))
            .background(
                isSelected
                    ? AnyShapeStyle(Theme.heroGradient)
                    : AnyShapeStyle(Theme.surfaceLow),
                in: .rect(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.surfaceHigh, lineWidth: isSelected ? 0 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(method.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
