import SwiftUI
import SwiftData

struct BrewListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Brew.createdAt, order: .reverse) private var brews: [Brew]

    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var appeared = false
    @Namespace private var addSheetNamespace

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if brews.isEmpty {
                BrewListEmptyState { showAddSheet = true }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Theme.cardSpacing) {
                        BrewHeroCard(brews: brews)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(reduceMotion ? .none : .smooth, value: appeared)

                        ForEach(brews) { brew in
                            NavigationLink(value: brew.persistentModelID) {
                                BrewCard(brew: brew)
                            }
                            .buttonStyle(.plain)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(reduceMotion ? .none : .smooth, value: appeared)
                        }
                    }
                    .padding(Theme.screenPadding)
                }
            }
        }
        .navigationTitle("Brews")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gearshape") { showSettings = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add brew", systemImage: "plus") { showAddSheet = true }
                    .matchedTransitionSource(id: "addBrew", in: addSheetNamespace)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NewBrewSheet()
                .navigationTransition(.zoom(sourceID: "addBrew", in: addSheetNamespace))
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let brew = context.model(for: id) as? Brew {
                BrewDetailView(brew: brew)
            }
        }
        .task { appeared = true }
    }
}

private struct BrewHeroCard: View {
    let brews: [Brew]

    private var favoriteMethodLabel: String {
        let counts = Dictionary(grouping: brews, by: \.method).mapValues(\.count)
        if let top = counts.max(by: { $0.value < $1.value })?.key {
            return "Mostly \(top.displayName)"
        }
        return "Welcome back"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("^[\(brews.count) brew](inflect: true) logged")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.85))
            Text(favoriteMethodLabel)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Theme.heroGradient, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.primary.opacity(0.25), radius: 16, y: 8)
    }
}

private struct BrewListEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No brews yet", systemImage: "cup.and.saucer")
        } description: {
            Text("Log your first brew to start dialing in your recipes.")
        } actions: {
            Button("Log a brew", action: onAdd)
                .buttonStyle(.gradient)
        }
    }
}

private struct BrewCard: View {
    let brew: Brew

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.softGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: brew.method.symbol)
                        .foregroundStyle(Theme.primary)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(brew.method.displayName)
                            .font(.headline)
                            .foregroundStyle(Theme.onBackground)
                        Spacer()
                        Text(brew.formattedRatio)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primary)
                    }
                    Text("\(formatted(brew.doseGrams))g → \(formatted(brew.yieldGrams))g · \(brew.formattedTime)")
                        .font(.caption)
                        .foregroundStyle(Theme.onBackgroundVariant)
                    HStack(spacing: 8) {
                        if let bag = brew.bag {
                            Label(bag.displayTitle, systemImage: "bag")
                                .font(.caption)
                                .foregroundStyle(Theme.onBackgroundVariant)
                                .lineLimit(1)
                        }
                        Spacer()
                        if let rating = brew.rating {
                            HStack(spacing: 2) {
                                ForEach(0..<rating, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                            .accessibilityElement()
                            .accessibilityLabel("\(rating) of 5 stars")
                        }
                        Text(brew.createdAt.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundStyle(Theme.onBackgroundVariant)
                    }
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}
