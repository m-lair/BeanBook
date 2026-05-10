import SwiftUI
import SwiftData

/// Bag detail — color block, brand eyebrow, big serif name, tasting + stats grid.
struct BagDetailView: View {
    let bag: Bag
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var didDelete = false

    private var sortedBrews: [Brew] {
        bag.brews.sorted { $0.createdAt > $1.createdAt }
    }

    private var avgRatio: Double {
        let ratios = bag.brews.compactMap { $0.ratio > 0 ? $0.ratio : nil }
        guard !ratios.isEmpty else { return 0 }
        return ratios.reduce(0, +) / Double(ratios.count)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    colorBlock
                    titleBlock
                    if !bag.tastingNotes.isEmpty { tastingBlock }
                    if let notes = bag.notes, !notes.isEmpty { descriptionBlock(notes) }
                    statsGrid
                    brewsList
                    Spacer().frame(height: 80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showEditSheet = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.ink2)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NewBagSheet(editing: bag)
        }
        .confirmationDialog(
            "Delete this bag?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete bag", role: .destructive) {
                didDelete = true
                context.delete(bag)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Brews on this bag will keep their settings but lose the bag link.")
        }
        .sensoryFeedback(.warning, trigger: didDelete)
    }

    private var colorBlock: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(bag.roastLevel.swatch)
                .frame(width: 90, height: 116)
                .shadow(color: bag.roastLevel.swatch.opacity(0.5), radius: 12, y: 6)
            // Subtle dot pattern
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.04))
                .frame(width: 90, height: 116)
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(20))
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(bag.brand.isEmpty ? "Bag" : bag.brand, color: Theme.accent)
            Text(bag.name.isEmpty ? "Untitled" : bag.name)
                .font(.system(size: 44, weight: .medium, design: .serif))
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)
            Text(metaLine)
                .font(Theme.body(13.5))
                .foregroundStyle(Theme.ink2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(28))
    }

    private var tastingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Tasting")
            tastingNotes
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(36))
    }

    private var tastingNotes: some View {
        let parts = Array(bag.tastingNotes.enumerated())
        return parts.reduce(into: Text("")) { acc, pair in
            let (i, n) = pair
            if i > 0 {
                acc = acc + Text(" · ").foregroundStyle(Theme.accent)
            }
            acc = acc + Text(n).foregroundStyle(Theme.ink)
        }
        .font(.system(size: 24, weight: .regular, design: .serif))
        .tracking(-0.4)
    }

    private func descriptionBlock(_ notes: String) -> some View {
        Text(notes)
            .font(Theme.body(14))
            .foregroundStyle(Theme.ink2)
            .lineSpacing(3)
            .padding(.horizontal, 28)
            .padding(.top, Theme.p(28))
    }

    private var statsGrid: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 0) {
                StatCell(label: "Brews", value: "\(bag.brews.count)")
                Rectangle().fill(Theme.rule).frame(width: 0.5, height: 50)
                StatCell(label: "Avg ratio",
                         value: avgRatio > 0 ? "1:\(avgRatio.formatted(.number.precision(.fractionLength(2))))" : "—")
                Rectangle().fill(Theme.rule).frame(width: 0.5, height: 50)
                StatCell(label: "Roasted",
                         value: bag.roastedOn?.formatted(date: .abbreviated, time: .omitted) ?? "—")
            }
            HairRule()
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(28))
    }

    private var brewsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("\(bag.brews.count) brew\(bag.brews.count == 1 ? "" : "s")")
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(sortedBrews) { brew in
                    NavigationLink(value: brew) {
                        BagBrewRow(brew: brew)
                    }
                    .buttonStyle(.plain)
                }
                if bag.brews.isEmpty {
                    Text("No brews logged yet.")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink3)
                        .padding(.vertical, 14)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(28))
    }

    private var metaLine: String {
        var parts: [String] = []
        if !bag.origin.isEmpty { parts.append(bag.origin) }
        parts.append(bag.roastLevel.displayName)
        if let p = bag.process { parts.append(p.displayName) }
        return parts.joined(separator: " · ")
    }
}

private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .medium, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Eyebrow(label).tracking(1.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

private struct BagBrewRow: View {
    let brew: Brew

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(brew.method.displayName)
                        .font(Theme.body(14.5, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Text(brew.createdAt.formatted(.relative(presentation: .numeric)))
                        .font(Theme.body(11.5))
                        .foregroundStyle(Theme.ink3)
                }
                Spacer()
                HStack(spacing: 12) {
                    if let r = brew.rating, r > 0 {
                        RatingDots(value: r, size: 5)
                    }
                    RatioText(brew.ratio)
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.vertical, 14)
        }
        .contentShape(.rect)
    }
}

// Compact brew row used by other features (preserved for compatibility).
struct BrewRowCompact: View {
    let brew: Brew

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: brew.method.symbol)
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink2)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(brew.method.displayName)
                    .font(Theme.body(14, weight: .medium))
                    .foregroundStyle(Theme.ink)
                Text("\(Int(brew.doseGrams))g → \(Int(brew.yieldGrams))g · \(brew.formattedTime) · \(brew.formattedRatio)")
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.ink2)
            }
            Spacer()
            Text(brew.createdAt.formatted(.relative(presentation: .numeric)))
                .font(Theme.body(11.5))
                .foregroundStyle(Theme.ink3)
        }
        .padding(.vertical, 4)
    }
}
