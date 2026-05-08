import SwiftUI
import SwiftData
import CoreLocation

/// Discover — folded-in catalog. Featured `accentSoft` card + list rows with color blocks.
struct ShopView: View {
    @Environment(CatalogService.self) private var catalog
    @Environment(LocationService.self) private var location
    @Environment(BagStore.self) private var bagStore
    @Environment(\.dismiss) private var dismiss

    let showsDoneButton: Bool

    @State private var roastFilter: RoastLevel? = nil
    @State private var toastMessage: String? = nil
    @State private var toastTrigger = 0
    @State private var toastTask: Task<Void, Never>?
    @State private var showingPaywall = false

    init(showsDoneButton: Bool = false) {
        self.showsDoneButton = showsDoneButton
    }

    /// Beans within this radius of the user are surfaced in "Near you".
    private static let nearbyRadiusMiles: Double = 250

    private var filtered: [CatalogBean] {
        guard let roastFilter else { return catalog.beans }
        return catalog.beans.filter { $0.roastLevel == roastFilter }
    }

    /// Roaster-deduplicated, distance-sorted nearby beans.
    /// Empty when location is unknown or no roaster is in range.
    private var nearbyBeans: [(bean: CatalogBean, miles: Double)] {
        guard let coord = location.coordinate else { return [] }
        var seenRoasters = Set<String>()
        let candidates: [(CatalogBean, Double)] = catalog.beans.compactMap { bean in
            guard let lat = bean.roasterLat, let lng = bean.roasterLng else { return nil }
            let beanCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let miles = coord.distanceMiles(to: beanCoord)
            guard miles <= Self.nearbyRadiusMiles else { return nil }
            return (bean, miles)
        }
        return candidates
            .sorted { $0.1 < $1.1 }
            .filter { seenRoasters.insert($0.0.roaster).inserted }
            .prefix(4)
            .map { (bean: $0.0, miles: $0.1) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    nearYouSection
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
            .task { location.requestIfNeeded() }

            if let toastMessage {
                ToastView(message: toastMessage)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .sensoryFeedback(.success, trigger: toastTrigger)
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallSheet(headline: "You've reached the free limit of \(ProQuota.bags) bags. Unlock Pro for unlimited.")
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
        RoastFilterRow(selection: $roastFilter)
    }

    private func featuredCard(_ bean: CatalogBean) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.accentSoft)

            // Hero: layered tilted "bag" tile with gradient depth, hairline, and a
            // floating roast-level micro-label. Anchored to the trailing edge so it
            // scales with the card width rather than relying on a fixed offset.
            heroShape(for: bean)
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                .padding(.top, -16)
                .padding(.trailing, -22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Eyebrow("Pick of the week", color: Theme.accent)
                }
                .padding(.bottom, 14)

                Eyebrow(bean.roaster, color: Theme.ink3)
                Text(bean.name)
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .tracking(-0.8)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)

                if !bean.origin.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.ink3)
                        Text(bean.origin)
                            .font(Theme.body(12, weight: .medium))
                            .foregroundStyle(Theme.ink2)
                            .tracking(0.2)
                            .lineLimit(1)
                    }
                    .padding(.top, 8)
                }

                Text(bean.description)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .frame(maxWidth: 220, alignment: .leading)
                    .padding(.top, 12)

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

                Button("Add to beans") { addToBags(bean) }
                    .buttonStyle(.accentPill)
                    .padding(.top, 20)
            }
            .padding(24)
            .frame(maxWidth: 260, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
    }

    /// Layered hero "bag" tile — gradient swatch + hairline + floating roast chip.
    private func heroShape(for bean: CatalogBean) -> some View {
        let swatch = bean.roastLevel.swatch
        return ZStack(alignment: .topTrailing) {
            // Soft echo behind, slightly larger and more rotated, lower opacity.
            RoundedRectangle(cornerRadius: 10)
                .fill(swatch.opacity(0.18))
                .frame(width: 116, height: 150)
                .rotationEffect(.degrees(14))
                .offset(x: -8, y: 6)

            // Front block: gradient fill + inner hairline.
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [swatch.opacity(0.95), swatch.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 110, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
                .rotationEffect(.degrees(8))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                .overlay(alignment: .topLeading) {
                    Text(bean.roastLevel.displayName.uppercased())
                        .font(Theme.body(9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white, in: .capsule)
                        .overlay(Capsule().stroke(Theme.rule, lineWidth: 0.5))
                        .rotationEffect(.degrees(8))
                        .offset(x: 6, y: -6)
                }
        }
        .frame(width: 140, height: 160, alignment: .topTrailing)
    }

    @ViewBuilder
    private var nearYouSection: some View {
        let entries = nearbyBeans
        if !entries.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Eyebrow("Near you", color: Theme.accent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 12)

                VStack(spacing: 0) {
                    ForEach(entries, id: \.bean.id) { entry in
                        NearbyRosterRow(bean: entry.bean, miles: entry.miles) {
                            addToBags(entry.bean)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var moreHeader: some View {
        Eyebrow("More from this week")
            .padding(.horizontal, 24)
            .padding(.top, 32)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(filtered.dropFirst()) { bean in
                CatalogBeanCard(bean: bean) { addToBags(bean) }
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
        do {
            try bagStore.create(
                brand: bean.roaster,
                name: bean.name,
                roastLevel: bean.roastLevel,
                origin: bean.origin,
                process: bean.process,
                tastingNotes: bean.tastingNotes,
                notes: bean.description
            )
        } catch is QuotaExceededError {
            showingPaywall = true
            return
        } catch {
            return
        }

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

private struct NearbyRosterRow: View {
    let bean: CatalogBean
    let miles: Double
    let onAdd: () -> Void

    private var distanceLabel: String {
        if miles < 1 { return "< 1 mi" }
        if miles < 10 { return String(format: "%.1f mi", miles) }
        return "\(Int(miles.rounded())) mi"
    }

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 14) {
                Circle()
                    .fill(bean.roastLevel.swatch)
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 0.75).blendMode(.overlay))
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(bean.roaster)
                    Text(bean.name)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 1)
                    HStack(spacing: 6) {
                        if let loc = bean.roasterLocationLabel {
                            Text(loc)
                                .font(Theme.body(11.5))
                                .foregroundStyle(Theme.ink2)
                        }
                        Text("·")
                            .font(Theme.body(11.5))
                            .foregroundStyle(Theme.ink3)
                        Text(distanceLabel)
                            .font(Theme.body(11.5, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.top, 1)
                }

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(bean.name)")
            }
            .padding(.vertical, 14)
        }
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
