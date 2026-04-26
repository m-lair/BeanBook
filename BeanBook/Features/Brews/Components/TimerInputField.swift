import SwiftUI

struct TimerInputField: View {
    @Binding var seconds: Int
    var label: String = "Brew time"

    @State private var running = false
    @State private var startedAt: Date?
    @State private var accumulated: Int = 0
    @State private var tick = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var displayed: String {
        let s = running
            ? accumulated + Int(tick.timeIntervalSince(startedAt ?? tick))
            : seconds
        if s < 60 { return String(format: "%ds", s) }
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(displayed)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Theme.onBackground)
                .frame(minWidth: 70, alignment: .leading)

            Spacer()

            Button {
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
            } label: {
                Label(running ? "Stop" : "Start", systemImage: running ? "stop.fill" : "play.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(running ? Theme.error : Theme.primary)
            .sensoryFeedback(.impact(weight: .medium), trigger: running)

            Button {
                running = false
                startedAt = nil
                accumulated = 0
                seconds = 0
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Theme.onBackgroundVariant)
        }
        .onReceive(timer) { _ in
            if running { tick = Date() }
        }
    }
}
