import SwiftUI
import SwiftData

/// "All brews" — destination of the Today screen's "All" link. Editorial list,
/// rule-separated rows; no toolbar Settings button (Settings now lives on Today).
struct BrewListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Brew.createdAt, order: .reverse) private var brews: [Brew]

    @State private var showAddSheet = false
    @Namespace private var addSheetNamespace

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if brews.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        list
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.accent)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Theme.ink)
                .matchedTransitionSource(id: "addBrew", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBrewSheet()
                .navigationTransition(.zoom(sourceID: "addBrew", in: addSheetNamespace))
        }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
        .navigationDestination(for: Bag.self) { BagDetailView(bag: $0) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("\(brews.count) logged")
            Text("Brews")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 24)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(brews.enumerated()), id: \.element.id) { _, brew in
                NavigationLink(value: brew) {
                    BrewListRow(brew: brew)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Text("No\n").foregroundStyle(Theme.ink))\(Text("brews yet.").foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
            Text("Log your first brew to start dialing in your recipes.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
                .frame(maxWidth: 280, alignment: .leading)
            Button("Log a brew") { showAddSheet = true }
                .buttonStyle(.primaryPill)
                .padding(.top, 16)
        }
        .padding(.horizontal, 32)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrewListRow: View {
    let brew: Brew

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(brew.method.displayName)
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    RatioText(brew.ratio)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(Theme.ink)
                    if let r = brew.rating, r > 0 {
                        RatingDots(value: r, size: 5)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .contentShape(.rect)
    }

    private var detail: String {
        let bag = brew.bag?.brand ?? "—"
        let date = brew.createdAt.formatted(.relative(presentation: .numeric))
        return "\(bag) · \(date)"
    }
}
