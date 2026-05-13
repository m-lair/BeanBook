import SwiftUI
import SwiftData

/// Saved-brew presets surfaced as a primary tab. Mirrors `C2Presets`.
struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

    @State private var prefillBrew: Brew?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if presets.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        list
                        Spacer().frame(height: 60)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $prefillBrew) { brew in
            NewBrewSheet(prefill: brew)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("\(presets.count) saved")
            Text("Recipes")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 24)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(Array(presets.enumerated()), id: \.element.id) { _, preset in
                Button {
                    let scratch = Brew(
                        method: preset.method,
                        doseGrams: preset.doseGrams,
                        yieldGrams: preset.yieldGrams,
                        brewTimeSeconds: preset.brewTimeSeconds,
                        grindSetting: preset.grindSetting,
                        waterTempC: preset.waterTempC
                    )
                    prefillBrew = scratch
                } label: {
                    PresetRow(preset: preset)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(Text("No\n").foregroundStyle(Theme.ink))\(Text("recipes.").foregroundStyle(Theme.accent))")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
            Text("Save a brew as a preset from the New Brew screen to keep its recipe handy.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
                .lineSpacing(3)
                .frame(maxWidth: 280, alignment: .leading)
        }
        .padding(.horizontal, 32)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct PresetRow: View {
    let preset: BrewPreset

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: preset.method.symbol)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.ink3)
                        Eyebrow(preset.method.displayName)
                    }
                    Text(preset.name.isEmpty ? preset.method.displayName : preset.name)
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                    Text("\(numeric(preset.doseGrams))g · \(numeric(preset.yieldGrams))g · \(timeLabel)")
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                }
                Spacer()
                Text(formattedRatio)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 20)
            RatioBar(ratio: ratio, height: 2)
                .frame(maxWidth: 200, alignment: .leading)
                .padding(.bottom, 4)
        }
        .contentShape(.rect)
    }

    private var ratio: Double {
        guard preset.doseGrams > 0 else { return 0 }
        return preset.yieldGrams / preset.doseGrams
    }

    private var formattedRatio: String {
        guard ratio > 0 else { return "—" }
        return "1:\(ratio.formatted(.number.precision(.fractionLength(2))))"
    }

    private var timeLabel: String {
        let s = preset.brewTimeSeconds
        if s < 60 { return "\(s)s" }
        if s < 3600 { return Duration.seconds(s).formatted(.time(pattern: .minuteSecond)) }
        return Duration.seconds(s).formatted(.time(pattern: .hourMinute))
    }

    private func numeric(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : v.formatted(.number.precision(.fractionLength(1)))
    }
}
