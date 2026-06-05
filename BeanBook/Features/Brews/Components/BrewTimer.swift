import SwiftUI

/// Editorial countdown timer — counts down from a target brew duration to zero.
/// Tap “Start” to begin, “Pause”/“Resume” mid-run, “Reset” to clear. The number
/// turns forest-accent while running and shifts to success-green on completion.
struct BrewTimer: View {
    /// Two-way binding to the brew’s planned/elapsed time in seconds.
    /// While idle, this is the **target** the user is brewing toward (adjusted via the ±30s chips).
    /// When paused or finished, it reflects the actual elapsed time.
    @Binding var seconds: Int

    /// `true` shows time remaining (countdown), `false` shows time elapsed (countup).
    /// Either way, the underlying state tracks elapsed seconds — only the display differs.
    var countsDown: Bool = true

    @State private var phase: Phase = .idle
    @State private var target: TimeInterval = 30
    @State private var startDate: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var hasFinished = false

    @State private var isEditingTime = false
    @State private var editMinutes: Int = 0
    @State private var editSeconds: Int = 30
    @State private var didHydrate = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Phase: Hashable { case idle, running, paused, finished }

    private let lowerBound: Int = 5
    private let upperBound: Int = 7200

    var body: some View {
        VStack(spacing: 0) {
            Eyebrow(eyebrowLabel, color: eyebrowColor)
                .contentTransition(.opacity)
                .motion(Motion.transition, value: phase)

            TimelineView(.animation(minimumInterval: 0.05, paused: phase != .running)) { context in
                let elapsed = currentElapsed(at: context.date)
                let remaining = max(0, target - elapsed)
                let displayed = countsDown ? remaining : min(elapsed, target)
                TimerReadout(
                    text: format(displayed, isCountdown: countsDown),
                    color: displayColor
                )
                    .padding(.top, 18)
                    .contentShape(.rect)
                    .onTapGesture {
                        guard phase == .idle else { return }
                        let t = Int(target.rounded())
                        editMinutes = t / 60
                        editSeconds = t % 60
                        isEditingTime = true
                    }
                    .accessibilityHint(phase == .idle ? "Double tap to set timer duration" : "")
                    .onChange(of: remaining <= 0) { _, finished in
                        if finished && phase == .running {
                            DispatchQueue.main.async { finish() }
                        }
                    }
            }
            .accessibilityLabel(accessibilityTimeLabel)

            progressRail
                .padding(.top, 24)

            if phase == .idle {
                HStack(spacing: 10) {
                    AdjustPill(label: "−30s", enabled: target > Double(lowerBound)) {
                        adjust(by: -30)
                    }
                    AdjustPill(label: "+30s", enabled: target < Double(upperBound)) {
                        adjust(by: +30)
                    }
                }
                .padding(.top, 22)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            Button(action: toggle) {
                HStack(spacing: 8) {
                    Image(systemName: toggleSymbol)
                        .font(.system(size: 13, weight: .semibold))
                    Text(toggleLabel)
                }
            }
            .buttonStyle(.outlinePill)
            .padding(.top, phase == .idle ? 22 : 36)
            .sensoryFeedback(.impact(weight: .light), trigger: phase)

            Button(action: reset) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Reset")
                        .font(Theme.body(13, weight: .medium))
                }
                .foregroundStyle(Theme.ink2)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .opacity(canReset ? 1 : 0)
            .allowsHitTesting(canReset)
            .motion(Motion.control, value: canReset)
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.success, trigger: hasFinished)
        .motion(Motion.transition, value: phase)
        .onAppear {
            guard !didHydrate else { return }
            didHydrate = true
            hydrateFromBinding()
        }
        .onDisappear { commitElapsed() }
        .sheet(isPresented: $isEditingTime) {
            TimeEditSheet(
                minutes: $editMinutes,
                seconds: $editSeconds,
                lowerBound: lowerBound,
                upperBound: upperBound,
                onCommit: applyEditedTime
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
    }

    private func applyEditedTime() {
        let total = editMinutes * 60 + editSeconds
        let clamped = min(max(total, lowerBound), upperBound)
        target = TimeInterval(clamped)
        seconds = clamped
    }

    // MARK: - Subviews

    private var progressRail: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: phase != .running)) { context in
            let elapsed = currentElapsed(at: context.date)
            let progress = target > 0 ? min(elapsed / target, 1) : 0
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.rule)
                        .frame(height: 2)
                    Capsule()
                        .fill(phase == .finished ? Theme.success : Theme.accent)
                        .frame(width: geo.size.width * progress, height: 2)
                        .animation(reduceMotion ? nil : .linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 2)
            .frame(maxWidth: 220)
        }
    }

    // MARK: - Computed

    private var canReset: Bool { phase != .idle || accumulated > 0 }

    private var eyebrowLabel: String {
        switch phase {
        case .idle: "Timer"
        case .running: "Brewing"
        case .paused: "Paused"
        case .finished: "Done"
        }
    }

    private var eyebrowColor: Color {
        switch phase {
        case .running: Theme.accent
        case .finished: Theme.success
        default: Theme.ink3
        }
    }

    private var displayColor: Color {
        switch phase {
        case .running: Theme.accent
        case .finished: Theme.success
        default: Theme.ink
        }
    }

    private var toggleLabel: String {
        switch phase {
        case .idle: "Start timer"
        case .running: "Pause"
        case .paused: "Resume"
        case .finished: "Start over"
        }
    }

    private var toggleSymbol: String {
        switch phase {
        case .idle: "play.fill"
        case .running: "pause.fill"
        case .paused: "play.fill"
        case .finished: "arrow.counterclockwise"
        }
    }

    private var accessibilityTimeLabel: String {
        let elapsed = currentElapsed(at: .now)
        let s = countsDown
            ? max(0, Int(target - elapsed))
            : max(0, Int(min(elapsed, target)))
        let m = s / 60
        let r = s % 60
        let suffix = countsDown ? "remaining" : "elapsed"
        let timeDescription = m > 0 ? "\(m) minutes \(r) seconds \(suffix)" : "\(r) seconds \(suffix)"
        return "\(timeDescription), \(eyebrowLabel)"
    }

    private func currentElapsed(at now: Date) -> TimeInterval {
        switch phase {
        case .running:
            guard let start = startDate else { return accumulated }
            return accumulated + now.timeIntervalSince(start)
        case .idle, .paused, .finished:
            return accumulated
        }
    }

    private func format(_ t: TimeInterval, isCountdown: Bool) -> String {
        // Hide tenths at the natural endpoint of each mode:
        //  - countdown: zero is "Done", just show 0:00
        //  - countup: starting at zero, show 0:00 until the user begins (no jittery .0)
        if isCountdown && t <= 0 { return "0:00" }
        if !isCountdown && t == 0 && phase == .idle { return "0:00" }
        let totalTenths = max(0, Int((t * 10).rounded(.down)))
        let m = totalTenths / 600
        let s = (totalTenths / 10) % 60
        let tenths = totalTenths % 10
        return String(format: "%d:%02d.%d", m, s, tenths)
    }

    // MARK: - Actions

    private func toggle() {
        switch phase {
        case .idle:
            startDate = Date()
            phase = .running
        case .running:
            if let start = startDate {
                accumulated += Date().timeIntervalSince(start)
            }
            startDate = nil
            seconds = Int(accumulated.rounded())
            phase = .paused
        case .paused:
            startDate = Date()
            phase = .running
        case .finished:
            // “Start over” — clear and restart from idle.
            reset()
        }
    }

    private func finish() {
        startDate = nil
        accumulated = target
        seconds = Int(target.rounded())
        phase = .finished
        hasFinished.toggle()
    }

    private func reset() {
        startDate = nil
        accumulated = 0
        phase = .idle
        // Preserve `target` so the user keeps their chosen duration.
        seconds = Int(target.rounded())
    }

    private func adjust(by delta: Int) {
        let next = min(max(Int(target.rounded()) + delta, lowerBound), upperBound)
        target = TimeInterval(next)
        seconds = next
    }

    private func hydrateFromBinding() {
        // Initialize target from whatever the parent passed in (method default).
        let initial = max(seconds, lowerBound)
        target = TimeInterval(initial)
        seconds = initial
    }

    private func commitElapsed() {
        // If the user advances to the next step mid-run, freeze elapsed time.
        if phase == .running, let start = startDate {
            accumulated += Date().timeIntervalSince(start)
            startDate = nil
        }
        // Save whichever is meaningful: elapsed time if they ran the timer,
        // otherwise the target they planned for.
        if accumulated > 0 {
            seconds = Int(accumulated.rounded())
        } else {
            seconds = max(lowerBound, Int(target.rounded()))
        }
    }
}

private struct TimeEditSheet: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    let lowerBound: Int
    let upperBound: Int
    let onCommit: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var maxMinutes: Int { upperBound / 60 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack(spacing: 0) {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0...maxMinutes, id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text("min")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink2)

                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) { s in
                            Text(String(format: "%02d", s)).tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text("sec")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink2)
                }
                .frame(height: 180)
                .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .background(Theme.background)
            .navigationTitle("Set timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.ink2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onCommit()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.accent)
                    .disabled(minutes * 60 + seconds < lowerBound)
                }
            }
        }
    }
}

private struct TimerReadout: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 84, weight: .ultraLight, design: .serif))
            .monospacedDigit()
            .tracking(-2)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

private struct AdjustPill: View {
    let label: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.body(13, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.card, in: .capsule)
                .overlay(Capsule().stroke(Theme.rule, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .sensoryFeedback(.selection, trigger: label)
    }
}
