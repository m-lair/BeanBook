import SwiftUI
import SwiftData

struct BrewDetailView: View {
    @Bindable var brew: Brew
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showBrewAgain = false
    @State private var showDeleteConfirm = false
    @State private var didDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.cardSpacing) {
                BrewHeroCard(brew: brew)
                BrewParamsCard(brew: brew)
                if let notes = brew.notes, !notes.isEmpty {
                    BrewNotesCard(notes: notes)
                }
                Button {
                    showBrewAgain = true
                } label: {
                    Label("Brew this again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.gradient)
                .padding(.top, 8)
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(brew.method.displayName)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
                .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $showBrewAgain) {
            NewBrewSheet(prefill: brew)
        }
        .confirmationDialog(
            "Delete this brew?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete brew", role: .destructive) {
                didDelete = true
                context.delete(brew)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sensoryFeedback(.warning, trigger: didDelete)
    }
}

private struct BrewHeroCard: View {
    let brew: Brew

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: brew.method.symbol)
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(brew.formattedRatio)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .monospacedDigit()
            Text("\(brewNumeric(brew.doseGrams))g → \(brewNumeric(brew.yieldGrams))g · \(brew.formattedTime)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            if let rating = brew.rating {
                HStack(spacing: 3) {
                    ForEach(0..<rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 4)
                .accessibilityElement()
                .accessibilityLabel("\(rating) of 5 stars")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.cardPadding)
        .padding(.vertical, 8)
        .background(Theme.heroGradient, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.primary.opacity(0.3), radius: 18, y: 10)
    }
}

private struct BrewParamsCard: View {
    let brew: Brew

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                BrewInfoRow(label: "Method", value: brew.method.displayName)
                BrewInfoRow(label: "Dose", value: "\(brewNumeric(brew.doseGrams)) g")
                BrewInfoRow(label: brew.method.yieldLabel, value: "\(brewNumeric(brew.yieldGrams)) g")
                BrewInfoRow(label: brew.method.timeLabel, value: brew.formattedTime)
                if let temp = brew.waterTempC {
                    BrewInfoRow(label: "Water temp", value: "\(Int(temp)) °C")
                }
                if let grind = brew.grindSetting, !grind.isEmpty {
                    BrewInfoRow(label: "Grind", value: grind)
                }
                if let bag = brew.bag {
                    BrewInfoRow(label: "Bag", value: bag.displayTitle)
                }
                BrewInfoRow(
                    label: "Logged",
                    value: brew.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
        }
    }
}

private struct BrewNotesCard: View {
    let notes: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.footnote)
                    .foregroundStyle(Theme.onBackgroundVariant)
                Text(notes)
                    .font(.body)
                    .foregroundStyle(Theme.onBackground)
            }
        }
    }
}

private struct BrewInfoRow: View {
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

private func brewNumeric(_ v: Double) -> String {
    if v.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(v)) }
    return v.formatted(.number.precision(.fractionLength(1)))
}
