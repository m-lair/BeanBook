import SwiftUI

/// Discover row — 44×56 color block + brand eyebrow + name + notes + circular add.
struct CatalogBeanCard: View {
    let bean: CatalogBean
    var onAddToBags: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(bean.roastLevel.swatch)
                    .frame(width: 44, height: 56)

                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(bean.roaster)
                    Text(bean.name)
                        .font(.system(size: 19, weight: .medium, design: .serif))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 1)
                    Text(bean.tastingNotes.prefix(3).joined(separator: ", "))
                        .font(Theme.body(11.5))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                        .padding(.top, 1)
                }

                Spacer()

                Button(action: onAddToBags) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(bean.name)")
            }
            .padding(.vertical, 16)
        }
    }
}
