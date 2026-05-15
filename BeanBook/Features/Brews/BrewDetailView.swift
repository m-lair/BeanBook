import SwiftUI
import SwiftData

/// Brew detail — editorial layout: eyebrow, big serif method title, large
/// animated ratio, italic note quote, rule-separated params, ink "Brew this again" pill.
struct BrewDetailView: View {
    let brew: Brew
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showBrewAgain = false
    @State private var showDeleteConfirm = false
    @State private var didDelete = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    ratioBlock
                    if let notes = brew.notes, !notes.isEmpty {
                        noteSection(notes)
                    }
                    params
                    brewAgain
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.ink2)
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
                didDelete = true
                context.delete(brew)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sensoryFeedback(.warning, trigger: didDelete)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(brew.createdAt.formatted(date: .abbreviated, time: .shortened))
            Text(brew.method.displayName)
                .font(.system(size: 48, weight: .medium, design: .serif))
                .tracking(-1.4)
                .foregroundStyle(Theme.ink)
                .padding(.top, 6)
            if let bag = brew.bag {
                NavigationLink(value: bag) {
                    HStack(spacing: 4) {
                        Text(bag.displayTitle)
                            .font(Theme.body(13.5, weight: .medium))
                            .foregroundStyle(Theme.accent)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(28))
    }

    private var ratioBlock: some View {
        VStack(spacing: 28) {
            BigRatio(
                ratio: brew.ratio,
                size: 96,
                sub: "\(numeric(brew.doseGrams))g · \(numeric(brew.yieldGrams))g · \(brew.formattedTime)"
            )
            VStack(spacing: 6) {
                RatioBar(ratio: brew.ratio, height: 4)
                    .frame(maxWidth: 200)
                HStack {
                    Eyebrow("Dose").tracking(1)
                    Spacer()
                    Eyebrow("Yield").tracking(1)
                }
                .frame(maxWidth: 200)
            }
            if let r = brew.rating, r > 0 {
                RatingDots(value: r, size: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, Theme.p(48))
    }

    private func noteSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Note")
            Text(notes)
                .italic()
                .font(.system(size: 20, weight: .regular, design: .serif))
                .tracking(-0.3)
                .lineSpacing(3)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(44))
    }

    private var params: some View {
        VStack(spacing: 0) {
            RuleRow("Dose", value: "\(numeric(brew.doseGrams)) g")
            RuleRow(brew.method.yieldLabel.replacingOccurrences(of: " (g)", with: ""),
                    value: "\(numeric(brew.yieldGrams)) g")
            RuleRow("Time", value: brew.formattedTime)
            if let temp = brew.waterTempC {
                RuleRow("Water", value: "\(Int(temp))°C")
            }
            RuleRow("Grind", value: brew.grindSetting?.isEmpty == false ? brew.grindSetting ?? "—" : "—")
        }
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(36))
    }

    private var brewAgain: some View {
        Button {
            showBrewAgain = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                Text("Brew this again")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primaryPill)
        .padding(.horizontal, 28)
        .padding(.top, Theme.p(36))
    }

    private func numeric(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : v.formatted(.number.precision(.fractionLength(1)))
    }
}
