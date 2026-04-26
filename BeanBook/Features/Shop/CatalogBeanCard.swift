import SwiftUI

struct CatalogBeanCard: View {
    let bean: CatalogBean
    var onAddToBags: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bean.roaster)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primary)
                            .textCase(.uppercase)
                        Text(bean.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.onBackground)
                    }
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Theme.primary.opacity(0.6))
                        .accessibilityHidden(true)
                }

                HStack(spacing: 6) {
                    metaChip(bean.origin)
                    metaChip(bean.roastLevel.displayName)
                    metaChip(bean.process.displayName)
                }

                if !bean.tastingNotes.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(bean.tastingNotes, id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Theme.primaryContainer.opacity(0.4), in: .capsule)
                        }
                    }
                }

                Text(bean.description)
                    .font(.callout)
                    .foregroundStyle(Theme.onBackgroundVariant)
                    .lineLimit(3)

                HStack(spacing: 10) {
                    Button(action: onAddToBags) {
                        Label("Add to Bags", systemImage: "bag.badge.plus")
                    }
                    .buttonStyle(.gradient)

                    if let url = bean.url {
                        Link(destination: url) {
                            Label("Buy", systemImage: "arrow.up.right")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .foregroundStyle(Theme.onBackground)
                                .background(Theme.surfaceHigh, in: .capsule)
                        }
                    }
                }
            }
        }
    }

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(Theme.onBackgroundVariant)
            .background(Theme.surfaceHigh.opacity(0.6), in: .capsule)
    }
}
