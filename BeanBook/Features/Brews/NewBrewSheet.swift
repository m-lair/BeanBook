import SwiftUI
import SwiftData

/// 4-step new-brew flow — Method → Bag → Ratio → Rate.
/// Mirrors `C2NewBrew` with progress ticks, save-success overlay, and prefill.
struct NewBrewSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

    /// Optional bag to pre-link.
    var initialBag: Bag? = nil
    /// Optional brew to pre-fill from (for "Brew this again").
    var prefill: Brew? = nil

    @State private var step: Int = 0
    @State private var method: BrewMethod = .espresso
    @State private var bag: Bag?
    @State private var dose: Double = 18
    @State private var yield: Double = 36
    @State private var brewTimeSeconds: Int = 30
    @State private var grindSetting: String = ""
    @State private var waterTempC: Double?
    @State private var rating: Int? = nil
    @State private var notes: String = ""

    @State private var saveAsPreset = false
    @State private var presetName: String = ""

    @State private var showSaved = false
    @State private var savedScale: CGFloat = 0
    @State private var didHydrate = false

    @AppStorage("timerCountsDown") private var timerCountsDown = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ratio: Double {
        guard dose > 0 else { return 0 }
        return yield / dose
    }

    private var ratingLabel: String {
        switch rating ?? 0 {
        case 0: "Tap to rate"
        case 1: "Off"
        case 2: "OK"
        case 3: "Good"
        case 4: "Great"
        case 5: "Outstanding"
        default: "—"
        }
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Theme.ink2)
                    }
                    ToolbarItem(placement: .principal) {
                        progressIndicator
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
        .task { hydrate() }
        .task(id: showSaved) {
            guard showSaved else { return }
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private var content: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                stepHeader
                ScrollView {
                    Group {
                        switch step {
                        case 0: methodStep
                        case 1: bagStep
                        case 2: ratioStep
                        case 3: timerStep
                        default: rateStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    .padding(.bottom, 140)
                }
                .scrollIndicators(.hidden)
                .animation(.snappy(duration: 0.32), value: step)
            }

            VStack {
                Spacer()
                bottomBar
            }

            if showSaved { savedOverlay }
        }
    }

    // MARK: - Toolbar progress indicator

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.accent : Theme.rule)
                    .frame(width: i == step ? 26 : 16, height: 2)
            }
        }
        .animation(.snappy(duration: 0.32), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of 5")
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Step \(step + 1) of 5")
                .contentTransition(.opacity)
            Text(stepTitle)
                .font(.system(size: 32, weight: .medium, design: .serif))
                .tracking(-0.9)
                .foregroundStyle(Theme.ink)
                .id(stepTitle)
                .transition(.opacity.combined(with: .offset(y: 6)))
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.3), value: step)
    }

    private var stepTitle: String {
        switch step {
        case 0: "How are you brewing today?"
        case 1: "What are you brewing?"
        case 2: "And the ratio?"
        case 3: "Time the pour."
        default: "How was it?"
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Button {
                advance()
            } label: {
                Text(step < 4 ? "Continue" : "Save brew")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryPill)

            if step > 0 {
                Button {
                    withAnimation(.snappy(duration: 0.3)) { step -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(Theme.body(13, weight: .medium))
                    }
                    .foregroundStyle(Theme.ink2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .padding(.top, 16)
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background],
                startPoint: .top, endPoint: .center
            )
            .frame(height: 100)
            .offset(y: 40),
            alignment: .top
        )
        .animation(.snappy(duration: 0.3), value: step)
    }

    // MARK: - Steps

    private var methodStep: some View {
        VStack(spacing: 0) {
            MethodPicker(selection: $method)
                .onChange(of: method) { _, newValue in
                    applyMethodDefaultsIfFresh(newValue)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    private var bagStep: some View {
        VStack(spacing: 0) {
            ForEach(bags) { b in
                Button {
                    bag = b
                } label: {
                    VStack(spacing: 0) {
                        HairRule()
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(b.roastLevel.swatch)
                                .frame(width: 6, height: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Eyebrow(b.brand.isEmpty ? "Bag" : b.brand)
                                Text(b.name.isEmpty ? "Untitled" : b.name)
                                    .font(.system(size: 18,
                                                  weight: bag?.id == b.id ? .semibold : .regular,
                                                  design: .serif))
                                    .tracking(-0.3)
                                    .foregroundStyle(bag?.id == b.id ? Theme.accent : Theme.ink)
                            }
                            Spacer()
                            if bag?.id == b.id {
                                Circle().fill(Theme.accent).frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                bag = nil
            } label: {
                VStack(spacing: 0) {
                    HairRule()
                    HStack {
                        Text("Skip — no bag")
                            .font(Theme.body(14))
                            .foregroundStyle(bag == nil ? Theme.accent : Theme.ink2)
                        Spacer()
                        if bag == nil {
                            Circle().fill(Theme.accent).frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 16)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    private var ratioStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                BigRatio(ratio: ratio, size: 84)
                RatioBar(ratio: ratio, height: 3)
                    .frame(maxWidth: 220)
            }
            .padding(.top, 8)

            VStack(spacing: 0) {
                StepperRow(label: "Dose", value: $dose, unit: "g",
                           range: method.doseRange, stepValue: 1)
                StepperRow(label: method.yieldLabel.replacingOccurrences(of: " (g)", with: ""),
                           value: $yield, unit: "g",
                           range: method.yieldRange, stepValue: 1)
            }
            .padding(.top, 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
    }

    private var timerStep: some View {
        BrewTimer(seconds: $brewTimeSeconds, countsDown: timerCountsDown)
            .padding(.horizontal, 24)
            .padding(.top, 36)
    }

    private var rateStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 14) {
                StarRating(rating: $rating, dotSize: 24)
                Eyebrow(ratingLabel).tracking(1.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            HairRule().padding(.top, 32)
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow("Note")
                TextField("How did it taste?", text: $notes, axis: .vertical)
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3...6)
                    .submitLabel(.done)
            }
            .padding(.top, 20)

            HairRule().padding(.top, 24)
            Toggle(isOn: $saveAsPreset) {
                Text("Save as recipe")
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.accent)
            .padding(.top, 18)

            if saveAsPreset {
                TextField("Recipe name", text: $presetName)
                    .font(Theme.body(14))
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    // MARK: - Save success overlay

    private var savedOverlay: some View {
        ZStack {
            Theme.background.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 76, height: 76)
                        .shadow(color: Theme.accentGlow, radius: 14, y: 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(savedScale)
                .onAppear {
                    if reduceMotion {
                        savedScale = 1
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            savedScale = 1
                        }
                    }
                }

                VStack(spacing: 6) {
                    Text("Saved.")
                        .font(.system(size: 22, weight: .medium, design: .serif))
                        .tracking(-0.5)
                        .foregroundStyle(Theme.ink)
                    Text("\(formattedRatio) · \(formattedTime)")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink2)
                }
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saved. \(formattedRatio), \(formattedTime).")
    }

    private var formattedRatio: String {
        ratio > 0 ? "1:\(ratio.formatted(.number.precision(.fractionLength(2))))" : "—"
    }

    private var formattedTime: String {
        let s = brewTimeSeconds
        if s < 60 { return "\(s)s" }
        return Duration.seconds(s).formatted(.time(pattern: .minuteSecond))
    }

    // MARK: - Lifecycle

    private func advance() {
        if step < 4 {
            withAnimation(.snappy(duration: 0.32)) { step += 1 }
        } else {
            save()
        }
    }

    private func save() {
        let brew = Brew(
            method: method,
            doseGrams: dose,
            yieldGrams: yield,
            brewTimeSeconds: brewTimeSeconds,
            grindSetting: grindSetting.isEmpty ? nil : grindSetting,
            waterTempC: waterTempC,
            rating: rating,
            notes: notes.isEmpty ? nil : notes,
            bag: bag
        )
        context.insert(brew)

        if saveAsPreset {
            let trimmed = presetName.trimmingCharacters(in: .whitespaces)
            let name = trimmed.isEmpty ? "\(method.displayName) recipe" : trimmed
            let preset = BrewPreset(
                name: name,
                method: method,
                doseGrams: dose,
                yieldGrams: yield,
                brewTimeSeconds: brewTimeSeconds,
                grindSetting: grindSetting.isEmpty ? nil : grindSetting,
                waterTempC: waterTempC
            )
            context.insert(preset)
        }

        try? context.save()

        withAnimation(.easeOut(duration: 0.25)) { showSaved = true }
    }

    private func hydrate() {
        guard !didHydrate else { return }
        if let prefill {
            method = prefill.method
            dose = prefill.doseGrams
            yield = prefill.yieldGrams
            brewTimeSeconds = prefill.brewTimeSeconds
            grindSetting = prefill.grindSetting ?? ""
            waterTempC = prefill.waterTempC
            bag = prefill.bag
            step = 1
        } else if let initialBag {
            bag = initialBag
            applyMethodDefaultsIfFresh(method)
        } else {
            applyMethodDefaultsIfFresh(method)
        }
        didHydrate = true
    }

    private func applyMethodDefaultsIfFresh(_ method: BrewMethod) {
        dose = method.defaultDose
        yield = method.defaultYield
        brewTimeSeconds = method.defaultTimeSeconds
        waterTempC = method.defaultWaterTempC
    }
}

// MARK: - Stepper rows

private struct StepperRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    let stepValue: Double

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                Text(label)
                    .font(Theme.body(14.5))
                    .foregroundStyle(Theme.ink2)
                Spacer()
                stepper
            }
            .padding(.vertical, 18)
        }
    }

    private var stepper: some View {
        HStack(spacing: 14) {
            StepperButton(symbol: "−") {
                withAnimation(.snappy(duration: 0.25)) {
                    value = max(range.lowerBound, value - stepValue)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(numericString(value))
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .tracking(-0.4)
                    .contentTransition(.numericText(value: value))
                Text(unit)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink3)
            }
            .frame(minWidth: 70)
            .sensoryFeedback(.selection, trigger: value)

            StepperButton(symbol: "+") {
                withAnimation(.snappy(duration: 0.25)) {
                    value = min(range.upperBound, value + stepValue)
                }
            }
        }
    }

    private func numericString(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : v.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct StepperIntRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                Text(label)
                    .font(Theme.body(14.5))
                    .foregroundStyle(Theme.ink2)
                Spacer()
                HStack(spacing: 14) {
                    StepperButton(symbol: "−") {
                        withAnimation(.snappy(duration: 0.25)) {
                            value = max(range.lowerBound, value - 1)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(String(value))
                            .font(.system(size: 24, weight: .medium, design: .serif))
                            .monospacedDigit()
                            .foregroundStyle(Theme.ink)
                            .tracking(-0.4)
                            .contentTransition(.numericText(value: Double(value)))
                        Text(unit)
                            .font(Theme.body(13))
                            .foregroundStyle(Theme.ink3)
                    }
                    .frame(minWidth: 70)
                    .sensoryFeedback(.selection, trigger: value)

                    StepperButton(symbol: "+") {
                        withAnimation(.snappy(duration: 0.25)) {
                            value = min(range.upperBound, value + 1)
                        }
                    }
                }
            }
            .padding(.vertical, 18)
        }
    }
}

/// Reusable circular −/+ stepper button with a press-scale.
private struct StepperButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 17))
                .foregroundStyle(Theme.ink)
                .frame(width: 34, height: 34)
                .background(Theme.card, in: .circle)
                .overlay(Circle().stroke(Theme.rule, lineWidth: 0.5))
        }
        .buttonStyle(StepperPressStyle())
        .accessibilityLabel(symbol == "+" ? "Increase" : "Decrease")
    }
}

private struct StepperPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
