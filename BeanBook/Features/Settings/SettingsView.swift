import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notifications

    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("preferredUnit") private var preferredUnit: String = "g"

    @Query private var presets: [BrewPreset]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.cardSpacing) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Reminders")
                            .font(.headline)
                            .foregroundStyle(Theme.onBackground)
                        Toggle(isOn: $dailyReminderEnabled) {
                            Label("Daily brew reminder", systemImage: "bell")
                        }
                        .onChange(of: dailyReminderEnabled) { _, on in
                            handleReminderToggle(on)
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Units")
                            .font(.headline)
                            .foregroundStyle(Theme.onBackground)
                        Picker("Weight unit", selection: $preferredUnit) {
                            Text("Grams").tag("g")
                            Text("Ounces").tag("oz")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Presets")
                            .font(.headline)
                            .foregroundStyle(Theme.onBackground)
                        if presets.isEmpty {
                            Text("Save brew settings as presets from the New Brew screen.")
                                .font(.callout)
                                .foregroundStyle(Theme.onBackgroundVariant)
                        } else {
                            ForEach(presets) { preset in
                                PresetRow(preset: preset, onDelete: { delete(preset) })
                            }
                        }
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundStyle(Theme.onBackground)
                        Text("BeanBook is a local-first coffee log. Everything stays on this device.")
                            .font(.callout)
                            .foregroundStyle(Theme.onBackgroundVariant)
                    }
                }
            }
            .padding(Theme.screenPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func handleReminderToggle(_ on: Bool) {
        if on {
            Task { await notifications.scheduleDailyCoffeeReminder() }
        } else {
            notifications.cancelDailyCoffeeReminder()
        }
    }

    private func delete(_ preset: BrewPreset) {
        context.delete(preset)
        try? context.save()
    }
}

private struct PresetRow: View {
    let preset: BrewPreset
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: preset.method.symbol)
                .foregroundStyle(Theme.primary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(preset.name)
                    .font(.callout)
                    .fontWeight(.medium)
                Text("\(Int(preset.doseGrams))g → \(Int(preset.yieldGrams))g")
                    .font(.caption)
                    .foregroundStyle(Theme.onBackgroundVariant)
            }
            Spacer()
            Button("Delete \(preset.name)", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(Theme.onBackgroundVariant)
        }
        .padding(.vertical, 4)
    }
}
