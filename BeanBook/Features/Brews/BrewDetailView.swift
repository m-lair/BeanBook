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
                heroCard
                paramsCard
                if let notes = brew.notes, !notes.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundStyle(Theme.onBackgroundVariant)
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(Theme.onBackground)
                        }
                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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
                context.delete(brew)
                try? context.save()
                didDelete = true
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sensoryFeedback(.warning, trigger: didDelete)
    }

    private var heroCard: some View {
        VStack(spacing: 10) {
            Image(systemName: brew.method.symbol)
                .font(.system(size: 48))
                .foregroundStyle(.white)
            Text(brew.formattedRatio)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .monospacedDigit()
            Text("\(formatted(brew.doseGrams))g → \(formatted(brew.yieldGrams))g · \(brew.formattedTime)")
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.cardPadding)
        .padding(.vertical, 8)
        .background(Theme.heroGradient, in: .rect(cornerRadius: Theme.cardRadius))
        .shadow(color: Theme.primary.opacity(0.3), radius: 18, y: 10)
    }

    private var paramsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                row("Method", brew.method.displayName)
                row("Dose", "\(formatted(brew.doseGrams)) g")
                row(brew.method.yieldLabel, "\(formatted(brew.yieldGrams)) g")
                row(brew.method.timeLabel, brew.formattedTime)
                if let temp = brew.waterTempC {
                    row("Water temp", "\(Int(temp)) °C")
                }
                if let grind = brew.grindSetting, !grind.isEmpty {
                    row("Grind", grind)
                }
                if let bag = brew.bag {
                    row("Bag", bag.displayTitle)
                }
                row("Logged", brew.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
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

    private func formatted(_ v: Double) -> String {
        if v.truncatingRemainder(dividingBy: 1) == 0 { return String(Int(v)) }
        return String(format: "%.1f", v)
    }
}
