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
                    NumericField(label: method.doseLabel, value: $dose)
                    NumericField(label: method.yieldLabel, value: $yield)
                }

                LabeledField(label: method.timeLabel) {
                    TimerInputField(seconds: $brewTimeSeconds)
                }

                LabeledField(label: "Grind") {
                    TextField("e.g. 12 clicks, fine, 18", text: $grindSetting)
                }

                if method.usesTemperature {
                    LabeledField(label: "Water temp (°C)") {
                        WaterTempField(method: method, waterTempC: $waterTempC)
                    }
                }

                ratioRow
            }
        }
    }

    private var ratioRow: some View {
        HStack {
            Text("Ratio")
                .font(.footnote)
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
        return "1:\((yield / dose).formatted(.number.precision(.fractionLength(2))))"
    }
}

private struct NumericField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.onBackgroundVariant)
            TextField(
                "0",
                value: $value,
                format: .number.precision(.fractionLength(0...1))
            )
            .keyboardType(.decimalPad)
            .padding(10)
            .background(Theme.surfaceBright, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12).stroke(Theme.surfaceHigh, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WaterTempField: View {
    let method: BrewMethod
    @Binding var waterTempC: Double?

    @State private var local: Double = 0

    var body: some View {
        HStack {
            TextField(
                "—",
                value: $local,
                format: .number.precision(.fractionLength(0))
            )
            .keyboardType(.decimalPad)
            .onChange(of: local) { _, newValue in
                waterTempC = newValue == 0 ? nil : newValue
            }
            Text("°C")
                .foregroundStyle(Theme.onBackgroundVariant)
        }
        .task(id: method) {
            local = waterTempC ?? method.defaultWaterTempC ?? 0
        }
    }
}
