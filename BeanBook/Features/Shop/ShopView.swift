import SwiftUI
import SwiftData

struct ShopView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(\.modelContext) private var context

    @State private var roastFilter: RoastLevel? = nil
    @State private var toastMessage: String? = nil
    @State private var toastTrigger = 0

    private var filtered: [CatalogBean] {
        guard let roastFilter else { return catalog.beans }
        return catalog.beans.filter { $0.roastLevel == roastFilter }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    intro
                    filterChips
                    LazyVStack(spacing: Theme.cardSpacing) {
                        ForEach(filtered) { bean in
                            CatalogBeanCard(bean: bean) {
                                addToBags(bean)
                            }
                        }
                    }
                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "No matches",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("Try a different roast filter.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 80)
            }

            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Shop")
        .sensoryFeedback(.success, trigger: toastTrigger)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Discover beans")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(Theme.onBackground)
            Text("Curated picks from notable roasters. Tap to add to your Bags or buy direct.")
                .font(.callout)
                .foregroundStyle(Theme.onBackgroundVariant)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", selected: roastFilter == nil) {
                    roastFilter = nil
                }
                ForEach(RoastLevel.allCases) { level in
                    FilterChip(label: level.displayName, selected: roastFilter == level) {
                        roastFilter = level
                    }
                }
            }
        }
    }

    private func addToBags(_ bean: CatalogBean) {
        let bag = Bag(
            brand: bean.roaster,
            name: bean.name,
            roastLevel: bean.roastLevel,
            origin: bean.origin,
            process: bean.process,
            tastingNotes: bean.tastingNotes,
            notes: bean.description
        )
        context.insert(bag)
        try? context.save()

        toastMessage = "Added \(bean.name) to Bags"
        toastTrigger &+= 1
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.smooth) { toastMessage = nil }
        }
    }
}

private struct FilterChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? .white : Theme.onBackground)
                .background(
                    selected
                        ? AnyShapeStyle(Theme.heroGradient)
                        : AnyShapeStyle(Theme.surfaceLow),
                    in: .capsule
                )
                .overlay(
                    Capsule().stroke(Theme.surfaceHigh, lineWidth: selected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ToastView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(Theme.onBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(Theme.surfaceLow)
                    .glassEffect(
                        reduceTransparency ? .identity : .regular.tint(Theme.primary.opacity(0.15)),
                        in: .capsule
                    )
            }
            .shadow(color: Theme.cardShadowColor, radius: 12, y: 4)
    }
}
