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
                header
                infoCard
                brewsCard
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(bag.brand.isEmpty ? "Bag" : bag.brand)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showEditSheet = true }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
                context.delete(bag)
                try? context.save()
                didDelete = true
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Brews on this bag will keep their settings but lose the bag link.")
        }
        .sensoryFeedback(.warning, trigger: didDelete)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .fill(Theme.softGradient)
                    .frame(height: 180)
                if let data = bag.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                } else {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.primary.opacity(0.7))
                }
            }

            Text(bag.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.onBackground)
        }
    }

    private var infoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                infoRow("Origin", bag.origin.isEmpty ? "—" : bag.origin)
                infoRow("Roast", bag.roastLevel.displayName)
                if let p = bag.process {
                    infoRow("Process", p.displayName)
                }
                if let date = bag.roastedOn {
                    infoRow("Roasted", date.formatted(date: .abbreviated, time: .omitted))
                }
                if !bag.tastingNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasting notes")
                            .font(.caption)
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

    private var brewsCard: some View {
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
                    ForEach(bag.brews.sorted { $0.createdAt > $1.createdAt }) { brew in
                        NavigationLink(value: brew.persistentModelID) {
                            BrewRowCompact(brew: brew)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(brew.method.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.onBackground)
                Text("\(Int(brew.doseGrams))g → \(Int(brew.yieldGrams))g · \(brew.formattedTime) · \(brew.formattedRatio)")
                    .font(.caption2)
                    .foregroundStyle(Theme.onBackgroundVariant)
            }
            Spacer()
            Text(brew.createdAt.formatted(.relative(presentation: .numeric)))
                .font(.caption2)
                .foregroundStyle(Theme.onBackgroundVariant)
        }
        .padding(.vertical, 4)
    }
}
