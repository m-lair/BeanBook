import SwiftUI
import SwiftData

/// Settings — grouped list, mirrors `C2Settings` from the design.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notifications

    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("preferredUnit") private var preferredUnit: String = "g"
    @AppStorage("autoPrefillFromLast") private var autoPrefill = true
    @AppStorage("timerCountsDown") private var timerCountsDown = true

    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]
    @State private var brewCount: Int = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    title
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
        .task {
            brewCount = (try? context.fetchCount(FetchDescriptor<Brew>())) ?? 0
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
            SettingsRow(label: "Theme", value: "Light")
            SettingsRow(label: "Default method", value: "Espresso")
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
            SettingsRow(label: "Brews logged", value: "\(brewCount)")
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
    init(label: String, value: String) {
        self.label = label
        self.trailing = { SettingsValueTrailing(value: value) }
    }
}

struct SettingsValueTrailing: View {
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink3)
        }
    }
}
