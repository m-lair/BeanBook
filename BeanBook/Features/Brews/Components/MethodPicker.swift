import SwiftUI

struct MethodPicker: View {
    @Binding var selection: BrewMethod

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BrewMethod.allCases) { method in
                    Button {
                        withAnimation(.snappy) { selection = method }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: method.symbol)
                                .font(.title3)
                            Text(method.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .frame(width: 84, height: 76)
                        .foregroundStyle(selection == method ? .white : Theme.onBackground)
                        .background(
                            selection == method
                                ? AnyShapeStyle(Theme.heroGradient)
                                : AnyShapeStyle(Theme.surfaceLow),
                            in: .rect(cornerRadius: 18)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Theme.surfaceHigh, lineWidth: selection == method ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: selection)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
