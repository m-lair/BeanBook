import SwiftUI
import SwiftData

/// Settings — grouped list, mirrors `C2Settings` from the design.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notifications
    @Environment(ProEntitlement.self) private var pro
    @Environment(BagStore.self) private var bagStore
    @Environment(BrewStore.self) private var brewStore
    @Environment(BrewPresetStore.self) private var brewPresetStore

    @State private var showingPaywall = false
    @State private var showingPalettePicker = false

    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("preferredUnit") private var preferredUnit: String = "g"
    @AppStorage("autoPrefillFromLast") private var autoPrefill = true
    @AppStorage("timerCountsDown") private var timerCountsDown = true
    @AppStorage("paletteID") private var paletteIDRaw: String = PaletteID.forest.rawValue
    @AppStorage("defaultBrewMethod") private var defaultBrewMethodRaw: String = BrewMethod.espresso.rawValue

    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]
    @Query private var bags: [Bag]
    @Query private var brews: [Brew]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
                    proSection
                    generalSection
                    brewingSection
                    dataSection
                    presetsSection
                    Spacer().frame(height: 60)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Theme.accent)
            }
        }
        .onChange(of: dailyReminderEnabled) { _, on in handleReminderToggle(on) }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack { PaywallSheet() }
        }
        .sheet(isPresented: $showingPalettePicker) {
            NavigationStack { PalettePickerSheet() }
        }
    }

    private var defaultBrewMethod: BrewMethod {
        BrewMethod(rawValue: defaultBrewMethodRaw) ?? .espresso
    }

    private var currentPaletteName: String {
        let id = PaletteID.canonical(rawValue: paletteIDRaw) ?? .forest
        return Palette.with(id: id).name
    }

    private var proSection: some View {
        SettingsSection(title: pro.isPro ? "BeanBook Pro" : "Upgrade") {
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: pro.isPro ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pro.isPro ? "Pro unlocked" : "BeanBook Pro")
                            .font(Theme.body(15, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(pro.isPro
                             ? "Thanks for supporting BeanBook."
                             : "One-time purchase · Unlimited everything · Future features included")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.ink2)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.ink3)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if !pro.isPro {
                Divider().background(Theme.rule).padding(.leading, 24)
                QuotaUsageRow(label: "Bags", count: bags.count, quota: ProQuota.bags)
                QuotaUsageRow(label: "Brews", count: brews.count, quota: ProQuota.brews)
                QuotaUsageRow(label: "Recipes", count: presets.count, quota: ProQuota.recipes)

                Button {
                    Task { await pro.restore() }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if case .loading = pro.purchaseState {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var title: some View {
        Text("Settings")
            .font(.system(size: 36, weight: .medium, design: .serif))
            .tracking(-1)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
    }

    private var generalSection: some View {
        SettingsSection(title: "General") {
            SettingsRow(label: "Units") {
                Picker("Units", selection: $preferredUnit) {
                    Text("Grams").tag("g")
                    Text("Ounces").tag("oz")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(Theme.ink2)
            }
            NavigableSettingsRow(label: "Theme", value: currentPaletteName) {
                showingPalettePicker = true
            }
            SettingsRow(label: "Default method") {
                Picker("Default method", selection: $defaultBrewMethodRaw) {
                    ForEach(BrewMethod.allCases) { method in
                        Text(method.displayName).tag(method.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(Theme.ink2)
            }
        }
    }

    private var brewingSection: some View {
        SettingsSection(title: "Brewing") {
            SettingsRow(label: "Daily reminder") {
                Toggle("Daily reminder", isOn: $dailyReminderEnabled)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            SettingsRow(label: "Auto-prefill from last brew") {
                Toggle("Auto-prefill from last brew", isOn: $autoPrefill)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            SettingsRow(label: "Timer style") {
                Picker("Timer style", selection: $timerCountsDown) {
                    Text("Count down").tag(true)
                    Text("Count up").tag(false)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(Theme.ink2)
            }
        }
    }

    private var dataSection: some View {
        SettingsSection(title: "Data") {
            SettingsRow(label: "Brews logged", value: "\(brews.count)")
            SettingsRow(label: "Saved recipes", value: "\(presets.count)")
        }
    }

    @ViewBuilder
    private var presetsSection: some View {
        if !presets.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow("Saved recipes")
                    Spacer()
                    Text("\(presets.count)")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink3)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                VStack(spacing: 0) {
                    ForEach(presets) { preset in
                        HStack {
                            Image(systemName: preset.method.symbol)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink2)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(preset.name.isEmpty ? preset.method.displayName : preset.name)
                                    .font(Theme.body(15))
                                    .foregroundStyle(Theme.ink)
                                Text("\(Int(preset.doseGrams))g → \(Int(preset.yieldGrams))g")
                                    .font(Theme.body(12))
                                    .foregroundStyle(Theme.ink2)
                            }
                            Spacer()
                            Button {
                                context.delete(preset)
                                try? context.save()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.ink3)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Theme.card)
                        Divider().background(Theme.rule)
                    }
                }
                .background(
                    Rectangle()
                        .fill(Theme.card)
                        .overlay(alignment: .top) { HairRule() }
                        .overlay(alignment: .bottom) { HairRule() }
                )
            }
            .padding(.bottom, 24)
        }
    }

    private func handleReminderToggle(_ on: Bool) {
        if on {
            Task { await notifications.scheduleDailyCoffeeReminder() }
        } else {
            notifications.cancelDailyCoffeeReminder()
        }
    }
}

// MARK: - Section primitives

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(title)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(
                Rectangle()
                    .fill(Theme.card)
                    .overlay(alignment: .top) { HairRule() }
                    .overlay(alignment: .bottom) { HairRule() }
            )
        }
        .padding(.bottom, 24)
    }
}

private struct SettingsRow<Trailing: View>: View {
    let label: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                Spacer()
                trailing()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider().background(Theme.rule).padding(.leading, 24)
        }
    }
}

extension SettingsRow where Trailing == SettingsValueTrailing {
    /// Read-only display row. No chevron, no tap target.
    init(label: String, value: String) {
        self.label = label
        self.trailing = { SettingsValueTrailing(value: value, navigable: false) }
    }
}

/// Navigable row variant — shows a chevron and wraps the entire row in a
/// Button so the whole surface is tappable.
private struct NavigableSettingsRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack {
                    Text(label)
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    SettingsValueTrailing(value: value, navigable: true)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .contentShape(.rect)
                Divider().background(Theme.rule).padding(.leading, 24)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsValueTrailing: View {
    let value: String
    var navigable: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
            if navigable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.ink3)
            }
        }
    }
}
