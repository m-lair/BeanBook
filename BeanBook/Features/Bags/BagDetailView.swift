import SwiftUI
import SwiftData

struct BagDetailView: View {
    @Bindable var bag: Bag
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var didDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.cardSpacing) {
                BagHeroCard(bag: bag)
                BagInfoCard(bag: bag)
                BagBrewsCard(bag: bag)
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(bag.brand.isEmpty ? "Bag" : bag.brand)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    Button("Edit", systemImage: "pencil") { showEditSheet = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
                .labelStyle(.iconOnly)
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
}

private struct BagHeroCard: View {
    let bag: Bag

    @State private var hero: UIImage?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .fill(Theme.softGradient)
                    .frame(height: 180)
                if let hero {
                    Image(uiImage: hero)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(.rect(cornerRadius: Theme.cardRadius))
                } else {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.primary.opacity(0.7))
                        .accessibilityHidden(true)
                }
            }

            Text(bag.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.onBackground)
        }
        .task(id: bag.imageData) {
            hero = bag.imageData.flatMap(UIImage.init(data:))
        }
    }
}

private struct BagInfoCard: View {
    let bag: Bag

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                BagInfoRow(label: "Origin", value: bag.origin.isEmpty ? "—" : bag.origin)
                BagInfoRow(label: "Roast", value: bag.roastLevel.displayName)
                if let p = bag.process {
                    BagInfoRow(label: "Process", value: p.displayName)
                }
                if let date = bag.roastedOn {
                    BagInfoRow(
                        label: "Roasted",
                        value: date.formatted(date: .abbreviated, time: .omitted)
                    )
                }
                if !bag.tastingNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasting notes")
                            .font(.footnote)
                            .foregroundStyle(Theme.onBackgroundVariant)
                        FlowLayout(spacing: 6) {
                            ForEach(bag.tastingNotes, id: \.self) { note in
                                Text(note)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Theme.primaryContainer.opacity(0.4), in: .capsule)
                            }
                        }
                    }
                }
                if let notes = bag.notes, !notes.isEmpty {
                    Divider()
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(Theme.onBackground)
                }
            }
        }
    }
}

private struct BagBrewsCard: View {
    let bag: Bag

    private var sortedBrews: [Brew] {
        bag.brews.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Brews on this bag")
                    .font(.headline)
                    .foregroundStyle(Theme.onBackground)

                if bag.brews.isEmpty {
                    Text("No brews logged yet.")
                        .font(.callout)
                        .foregroundStyle(Theme.onBackgroundVariant)
                } else {
                    ForEach(sortedBrews) { brew in
                        NavigationLink(value: brew.persistentModelID) {
                            BrewRowCompact(brew: brew)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct BagInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.onBackgroundVariant)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(Theme.onBackground)
        }
    }
}

struct BrewRowCompact: View {
    let brew: Brew

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: brew.method.symbol)
                .font(.title3)
                .foregroundStyle(Theme.primary)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(brew.method.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.onBackground)
                Text("\(Int(brew.doseGrams))g → \(Int(brew.yieldGrams))g · \(brew.formattedTime) · \(brew.formattedRatio)")
                    .font(.caption)
                    .foregroundStyle(Theme.onBackgroundVariant)
            }
            Spacer()
            Text(brew.createdAt.formatted(.relative(presentation: .numeric)))
                .font(.caption)
                .foregroundStyle(Theme.onBackgroundVariant)
        }
        .padding(.vertical, 4)
    }
}
