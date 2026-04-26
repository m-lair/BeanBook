import SwiftUI
import SwiftData

/// Discover — folded-in catalog. Featured `accentSoft` card + list rows with color blocks.
struct ShopView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ProEntitlement.self) private var pro

    @State private var roastFilter: RoastLevel? = nil
    @State private var toastMessage: String? = nil
    @State private var toastTrigger = 0
    @State private var toastTask: Task<Void, Never>?
    @State private var showingPaywall = false

    /// Stable global index of the bean in the unfiltered catalog.
    /// Free tier can add the first `ProQuota.catalog` beans; the rest are locked.
    private func isLocked(_ bean: CatalogBean) -> Bool {
        guard !pro.isPro else { return false }
        let idx = catalog.beans.firstIndex(of: bean) ?? Int.max
        return idx >= ProQuota.catalog
    }

    private var filtered: [CatalogBean] {
        guard let roastFilter else { return catalog.beans }
        return catalog.beans.filter { $0.roastLevel == roastFilter }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if let featured = filtered.first {
                        featuredCard(featured)
                            .padding(.top, 32)
                    }
                    moreHeader
                    list
                    Spacer().frame(height: 80)
                }
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)

            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.accent)
            }
        }
        .sensoryFeedback(.success, trigger: toastTrigger)
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallSheet(headline: "Unlock the full curated catalog with BeanBook Pro.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Discover · \(catalog.beans.count) curated")
                .padding(.bottom, 16)
            Text("\(Text("Worth a\n").foregroundStyle(Theme.ink))\(Text("look.").foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
            Text("Hand-picked roasters and coffees, refreshed weekly.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(2)
                .frame(maxWidth: 280, alignment: .leading)
                .padding(.top, 16)
            filterChips.padding(.top, 20)
        }
        .padding(.horizontal, 24)
    }

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(label: "All", selected: roastFilter == nil) { roastFilter = nil }
                ForEach(RoastLevel.allCases) { level in
                    FilterChip(label: level.displayName, selected: roastFilter == level) {
                        roastFilter = level
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func featuredCard(_ bean: CatalogBean) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.accentSoft)

            // Tilted color tile — anchored to the trailing edge so it scales with width
            // rather than relying on a fixed pixel offset.
            RoundedRectangle(cornerRadius: 8)
                .fill(bean.roastLevel.swatch.opacity(0.85))
                .frame(width: 110, height: 140)
                .rotationEffect(.degrees(8))
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.top, -20)
                .padding(.trailing, -30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(bean.roaster, color: Theme.accent)
                Text(bean.name)
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .tracking(-0.8)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)
                Text(bean.description)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .frame(maxWidth: 200, alignment: .leading)
                    .padding(.top, 10)

                FlowLayout(spacing: 6) {
                    ForEach(bean.tastingNotes.prefix(3), id: \.self) { note in
                        Text(note)
                            .font(Theme.body(11, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(.white, in: .capsule)
                            .overlay(Capsule().stroke(Theme.accent.opacity(0.25), lineWidth: 0.5))
                    }
                }
                .padding(.top, 14)

                Button(isLocked(bean) ? "Unlock with Pro" : "Add to beans") {
                    addToBags(bean)
                }
                    .buttonStyle(.primaryPill)
                    .padding(.top, 18)
            }
            .padding(24)
            .frame(maxWidth: 260, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 24)
    }

    private var moreHeader: some View {
        Eyebrow("More from this week")
            .padding(.horizontal, 24)
            .padding(.top, 32)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(filtered.dropFirst()) { bean in
                CatalogBeanCard(bean: bean, locked: isLocked(bean)) { addToBags(bean) }
            }
            if filtered.isEmpty {
                Text("No matches.")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink3)
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private func addToBags(_ bean: CatalogBean) {
        if isLocked(bean) {
            showingPaywall = true
            return
        }
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

        withAnimation(.easeOut(duration: 0.25)) {
            toastMessage = "Added \(bean.name) to Beans"
        }
        toastTrigger &+= 1
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toastMessage = nil }
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
                .font(Theme.body(11, weight: .semibold))
                .tracking(0.6)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? .white : Theme.ink2)
                .background(selected ? Theme.accent : Theme.card, in: .capsule)
                .overlay(Capsule().stroke(selected ? .clear : Theme.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

private struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(Theme.body(13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Theme.ink, in: .capsule)
            .shadow(color: Theme.ink.opacity(0.18), radius: 14, y: 8)
    }
}
