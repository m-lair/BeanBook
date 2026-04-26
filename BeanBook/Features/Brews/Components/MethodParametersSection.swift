import SwiftUI

struct MethodParametersSection: View {
    let method: BrewMethod
    @Binding var dose: Double
    @Binding var yield: Double
    @Binding var brewTimeSeconds: Int
    @Binding var grindSetting: String
    @Binding var waterTempC: Double?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    numericField(label: method.doseLabel, value: $dose)
                    numericField(label: method.yieldLabel, value: $yield)
                }

                LabeledField(label: method.timeLabel) {
                    TimerInputField(seconds: $brewTimeSeconds)
                }

                LabeledField(label: "Grind") {
                    TextField("e.g. 12 clicks, fine, 18", text: $grindSetting)
                }

                if method.usesTemperature {
                    LabeledField(label: "Water temp (°C)") {
                        HStack {
                            TextField(
                                "—",
                                value: Binding(
                                    get: { waterTempC ?? method.defaultWaterTempC ?? 93 },
                                    set: { waterTempC = $0 }
                                ),
                                format: .number.precision(.fractionLength(0))
                            )
                            .keyboardType(.numberPad)
                            Text("°C")
                                .foregroundStyle(Theme.onBackgroundVariant)
                        }
                    }
                }

                ratioRow
            }
        }
    }

    private var ratioRow: some View {
        HStack {
            Text("Ratio")
                .font(.caption)
                .foregroundStyle(Theme.onBackgroundVariant)
            Spacer()
            Text(formattedRatio)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primary)
        }
    }

    private var formattedRatio: String {
        guard dose > 0 else { return "—" }
        return String(format: "1:%.2f", yield / dose)
    }

    @ViewBuilder
    private func numericField(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.onBackgroundVariant)
            TextField(
                "0",
                value: value,
                format: .number.precision(.fractionLength(0...1))
            )
            .keyboardType(.decimalPad)
            .padding(10)
            .background(Theme.surfaceBright, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.surfaceHigh, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }
}

