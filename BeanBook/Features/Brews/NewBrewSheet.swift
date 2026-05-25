import SwiftUI
import SwiftData

/// 3-step new-brew flow — Context → Shot → Outcome.
/// Prefilled from last brew (or explicit `prefill: Brew`); hot-start lands on Shot step.
struct NewBrewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BrewStore.self) private var brewStore
    @Environment(BrewPresetStore.self) private var brewPresetStore
    @Environment(BagStore.self) private var bagStore

    @Query(sort: \Bag.createdAt, order: .reverse) private var bags: [Bag]
    @Query(sort: \BrewPreset.createdAt, order: .reverse) private var presets: [BrewPreset]

    @State private var showingPaywall = false
    @State private var paywallHeadline: String = ""

    /// Optional bag to pre-link.
    var initialBag: Bag? = nil
    /// Optional brew to pre-fill from (for "Brew this again" / Recipe launch).
    var prefill: Brew? = nil
    /// Optional preset to pre-fill from (for Recipe-tab launch; avoids creating a throwaway @Model).
    var prefillPreset: BrewPreset? = nil

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

    /// Snapshot of the values used to prefill the form. Used to render Δ-from-last hints.
    @State private var prefillSnapshot: PrefillSnapshot?
    /// The bag whose values were used for prefill — surfaced as a "recent" swap chip if user has a different pinned bag.
    @State private var recentBag: Bag?

    @State private var saveAsPreset = false
    @State private var presetName: String = ""

    @State private var showSaved = false
    @State private var savedScale: CGFloat = 0
    @State private var didHydrate = false

    @AppStorage("timerCountsDown") private var timerCountsDown = true
    @AppStorage("defaultBrewMethod") private var defaultBrewMethodRaw: String = BrewMethod.espresso.rawValue
    @AppStorage("autoPrefillFromLast") private var autoPrefillFromLast = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let totalSteps = 3

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
        default: "\u{2014}"
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
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallSheet(headline: paywallHeadline)
            }
        }
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

            ScrollView {
                VStack(spacing: 0) {
                    stepHeader
                    Group {
                        switch step {
                        case 0: contextStep
                        case 1: shotStep
                        default: outcomeStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)
            .animation(.snappy(duration: 0.32), value: step)

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
            ForEach(0..<Self.totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.accent : Theme.rule)
                    .frame(width: i == step ? 26 : 16, height: 2)
            }
        }
        .animation(.snappy(duration: 0.32), value: step)
        .accessibilityElement()
        .accessibilityLabel("Step \(step + 1) of \(Self.totalSteps)")
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Step \(step + 1) of \(Self.totalSteps)")
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
        case 0: "What are you brewing?"
        case 1: "Pull the shot."
        default: "How was it?"
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Button {
                advance()
            } label: {
                Text(step < Self.totalSteps - 1 ? "Next" : "Save brew")
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

    // MARK: - Step 0: Context (method + bag)

    private var contextStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Method")
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

            MethodPicker(selection: $method)
                .padding(.horizontal, 20)
                .onChange(of: method) { _, newValue in
                    applyMethodDefaultsIfFresh(newValue)
                }

            HairRule().padding(.top, 28)

            HStack {
                Eyebrow("Bag")
                Spacer()
                if let pinned = bagStore.pinnedBag, bag?.id == pinned.id {
                    Text("Pinned")
                        .font(Theme.body(11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 8)

            // "Recent: [bag]" swap affordance — only when a different bag is currently selected
            if let recent = recentBag, recent.id != bag?.id {
                Button {
                    bag = recent
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Recent: \(recent.displayTitle)")
                            .font(Theme.body(12))
                    }
                    .foregroundStyle(Theme.ink2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.card, in: .capsule)
                    .overlay(Capsule().stroke(Theme.rule, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            VStack(spacing: 0) {
                ForEach(bags) { b in
                    Button {
                        bag = b
                    } label: {
                        bagRow(b)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    bag = nil
                } label: {
                    VStack(spacing: 0) {
                        HairRule()
                        HStack {
                            Text("Skip \u{2014} no bag")
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
        }
        .padding(.top, 28)
    }

    private func bagRow(_ b: Bag) -> some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(b.roastLevel.swatch)
                    .frame(width: 6, height: 38)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Eyebrow(b.brand.isEmpty ? "Bag" : b.brand)
                        if b.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.accent)
                        }
                    }
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

    // MARK: - Step 1: Shot (dose, yield, time, grind)

    private var shotStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 22) {
                BigRatio(ratio: ratio, size: 84)
                RatioBar(ratio: ratio, height: 3)
                    .frame(maxWidth: 220)
            }
            .padding(.top, 8)

            VStack(spacing: 0) {
                StepperRow(
                    label: "Dose",
                    value: $dose,
                    unit: "g",
                    range: method.doseRange,
                    stepValue: 1,
                    caption: doseCaption
                )
                StepperRow(
                    label: method.yieldLabel.replacingOccurrences(of: " (g)", with: ""),
                    value: $yield,
                    unit: "g",
                    range: method.yieldRange,
                    stepValue: 1,
                    caption: yieldCaption
                )
            }
            .padding(.top, 28)

            VStack(spacing: 18) {
                BrewTimer(seconds: $brewTimeSeconds, countsDown: timerCountsDown)
                if let cap = timeCaption {
                    DeltaCaption(text: cap, reduceMotion: reduceMotion)
                }
            }
            .padding(.top, 28)

            GrindRow(value: $grindSetting, caption: grindCaption)
                .padding(.top, 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
    }

    // MARK: - Step 2: Outcome (rating, notes, save-as-recipe)

    private var outcomeStep: some View {
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

    // MARK: - Δ-from-last captions

    private var doseCaption: String? {
        guard let s = prefillSnapshot, s.dose != dose else { return nil }
        return "was \(format(s.dose)) g"
    }

    private var yieldCaption: String? {
        guard let s = prefillSnapshot, s.yield != yield else { return nil }
        return "was \(format(s.yield)) g"
    }

    private var timeCaption: String? {
        guard let s = prefillSnapshot, s.brewTimeSeconds != brewTimeSeconds else { return nil }
        return "was \(formatTime(s.brewTimeSeconds))"
    }

    private var grindCaption: String? {
        guard let s = prefillSnapshot,
              s.grindSetting != grindSetting,
              !s.grindSetting.isEmpty else { return nil }
        return "was \(s.grindSetting)"
    }

    private func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : v.formatted(.number.precision(.fractionLength(1)))
    }

    private func formatTime(_ s: Int) -> String {
        if s < 60 { return "\(s)s" }
        return Duration.seconds(s).formatted(.time(pattern: .minuteSecond))
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
        ratio > 0 ? "1:\(ratio.formatted(.number.precision(.fractionLength(2))))" : "\u{2014}"
    }

    private var formattedTime: String {
        formatTime(brewTimeSeconds)
    }

    // MARK: - Lifecycle

    private func advance() {
        if step < Self.totalSteps - 1 {
            withAnimation(.snappy(duration: 0.32)) { step += 1 }
        } else {
            save()
        }
    }

    private func save() {
        let resolvedGrind = grindSetting.isEmpty ? nil : grindSetting
        let resolvedNotes = notes.isEmpty ? nil : notes

        do {
            try brewStore.create(
                method: method,
                doseGrams: dose,
                yieldGrams: yield,
                brewTimeSeconds: brewTimeSeconds,
                grindSetting: resolvedGrind,
                waterTempC: waterTempC,
                rating: rating,
                notes: resolvedNotes,
                bag: bag
            )
        } catch is QuotaExceededError {
            paywallHeadline = "You've reached the free limit of \(ProQuota.brews) brews. Unlock Pro for unlimited."
            showingPaywall = true
            return
        } catch {
            return
        }

        withAnimation(.easeOut(duration: 0.25)) { showSaved = true }

        if saveAsPreset {
            let trimmed = presetName.trimmingCharacters(in: .whitespaces)
            let name = trimmed.isEmpty ? "\(method.displayName) recipe" : trimmed
            do {
                try brewPresetStore.create(
                    name: name,
                    method: method,
                    doseGrams: dose,
                    yieldGrams: yield,
                    brewTimeSeconds: brewTimeSeconds,
                    grindSetting: resolvedGrind,
                    waterTempC: waterTempC
                )
            } catch is QuotaExceededError {
                paywallHeadline = "You've reached the free limit of \(ProQuota.recipes) saved recipes. Unlock Pro for unlimited."
                showingPaywall = true
            } catch {
                // Same fall-through as above.
            }
        }
    }

    private func hydrate() {
        guard !didHydrate else { return }
        defer { didHydrate = true }

        if let prefillPreset {
            method = prefillPreset.method
            dose = prefillPreset.doseGrams
            yield = prefillPreset.yieldGrams
            brewTimeSeconds = prefillPreset.brewTimeSeconds
            grindSetting = prefillPreset.grindSetting ?? ""
            waterTempC = prefillPreset.waterTempC
            step = 1
            return
        }

        if let prefill {
            applyPrefill(from: prefill, jumpToShot: true)
            return
        }

        if let initialBag {
            bag = initialBag
            method = BrewMethod(rawValue: defaultBrewMethodRaw) ?? .espresso
            applyMethodDefaultsIfFresh(method)
            return
        }

        // Cold start. Honor autoPrefillFromLast: hydrate values (and bag) from most recent brew.
        if autoPrefillFromLast, let recent = brewStore.mostRecent() {
            applyPrefill(from: recent, jumpToShot: false)
            // Pin override: if user has a pinned bag and it's different from recent's bag,
            // surface pinned as the active selection but keep recent visible as a swap chip.
            if let pinned = bagStore.pinnedBag, pinned.id != recent.bag?.id {
                recentBag = recent.bag
                bag = pinned
            }
            return
        }

        // True cold-cold start: method defaults only.
        method = BrewMethod(rawValue: defaultBrewMethodRaw) ?? .espresso
        applyMethodDefaultsIfFresh(method)
        if let pinned = bagStore.pinnedBag {
            bag = pinned
        }
    }

    private func applyPrefill(from source: Brew, jumpToShot: Bool) {
        method = source.method
        dose = source.doseGrams
        yield = source.yieldGrams
        brewTimeSeconds = source.brewTimeSeconds
        grindSetting = source.grindSetting ?? ""
        waterTempC = source.waterTempC
        bag = source.bag
        prefillSnapshot = PrefillSnapshot(
            dose: source.doseGrams,
            yield: source.yieldGrams,
            brewTimeSeconds: source.brewTimeSeconds,
            grindSetting: source.grindSetting ?? ""
        )
        if jumpToShot { step = 1 }
    }

    private func applyMethodDefaultsIfFresh(_ method: BrewMethod) {
        dose = method.defaultDose
        yield = method.defaultYield
        brewTimeSeconds = method.defaultTimeSeconds
        waterTempC = method.defaultWaterTempC
    }
}

// MARK: - Prefill snapshot

private struct PrefillSnapshot: Equatable {
    let dose: Double
    let yield: Double
    let brewTimeSeconds: Int
    let grindSetting: String
}

// MARK: - Δ caption

private struct DeltaCaption: View {
    let text: String
    let reduceMotion: Bool

    var body: some View {
        Text(text)
            .font(Theme.body(11))
            .tracking(0.3)
            .foregroundStyle(Theme.ink3)
            .transition(reduceMotion ? .identity : .opacity)
    }
}

// MARK: - Stepper rows

private struct StepperRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>
    let stepValue: Double
    var caption: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(Theme.body(14.5))
                        .foregroundStyle(Theme.ink2)
                    if let caption {
                        DeltaCaption(text: caption, reduceMotion: reduceMotion)
                    }
                }
                Spacer()
                stepper
            }
            .padding(.vertical, 18)
        }
    }

    private var stepper: some View {
        HStack(spacing: 14) {
            StepperButton(symbol: "\u{2212}") {
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
                    StepperButton(symbol: "\u{2212}") {
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

// MARK: - Grind row

private struct GrindRow: View {
    @Binding var value: String
    var caption: String?

    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Grind")
                        .font(Theme.body(14.5))
                        .foregroundStyle(Theme.ink2)
                    if let caption {
                        DeltaCaption(text: caption, reduceMotion: reduceMotion)
                    }
                }
                Spacer()
                TextField("e.g. 2.4", text: $value)
                    .focused($focused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .tracking(-0.3)
                    .frame(minWidth: 90, maxWidth: 140)
                    .submitLabel(.done)
                    .onSubmit { focused = false }
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
