import SwiftUI

struct TimerInputField: View {
    @Binding var seconds: Int
    var label: String = "Brew time"

    @State private var running = false
    @State private var startedAt: Date?
    @State private var accumulated: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(displayed(at: context.date))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.onBackground)
                    .frame(minWidth: 70, alignment: .leading)
            }

            Spacer()

            Button(action: toggle) {
                Label(running ? "Stop" : "Start", systemImage: running ? "stop.fill" : "play.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(running ? Theme.error : Theme.primary)
            .sensoryFeedback(.impact(weight: .medium), trigger: running)

            Button("Reset", systemImage: "arrow.counterclockwise", action: reset)
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Theme.onBackgroundVariant)
        }
    }

    private func displayed(at now: Date) -> String {
        let s = running
            ? accumulated + Int(now.timeIntervalSince(startedAt ?? now))
            : seconds
        if s < 60 { return "\(s)s" }
        return Duration.seconds(s).formatted(.time(pattern: .minuteSecond))
    }

    private func toggle() {
        if running {
            if let started = startedAt {
                accumulated += Int(Date().timeIntervalSince(started))
            }
            seconds = accumulated
            running = false
            startedAt = nil
        } else {
            accumulated = seconds
            startedAt = Date()
            running = true
        }
    }

    private func reset() {
        running = false
        startedAt = nil
        accumulated = 0
        seconds = 0
    }
}
