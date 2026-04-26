import SwiftUI

struct TastingNotesEditor: View {
    @Binding var notes: [String]
    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !notes.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(notes, id: \.self) { note in
                        HStack(spacing: 6) {
                            Text(note)
                                .font(.footnote)
                                .fontWeight(.medium)
                            Button {
                                notes.removeAll { $0 == note }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.onBackgroundVariant)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.primaryContainer.opacity(0.4), in: .capsule)
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("Add a note (e.g. cherry, chocolate)", text: $draft)
                    .textInputAutocapitalization(.never)
                    .focused($focused)
                    .onSubmit(commit)
                Button("Add", action: commit)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(trimmed.isEmpty)
            }
        }
    }

    private var trimmed: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func commit() {
        let value = trimmed
        guard !value.isEmpty else { return }
        if !notes.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
            notes.append(value)
        }
        draft = ""
        focused = true
    }
}

/// Minimal flow layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for v in subviews {
            let size = v.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
