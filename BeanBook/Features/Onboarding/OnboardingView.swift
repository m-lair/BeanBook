import SwiftUI

/// First-run onboarding — single-screen, mirrors `C2Onboarding` from `c2-screens-2.jsx`.
struct OnboardingView: View {
    let onStart: () -> Void

    private struct Feature: Hashable {
        let symbol: String
        let title: String
        let detail: String
    }

    private let features: [Feature] = [
        .init(symbol: "scalemass.fill",
              title: "Log a brew",
              detail: "Method, dose, yield, time. Done in twenty seconds."),
        .init(symbol: "bag.fill",
              title: "Track your beans",
              detail: "Origin, roast date, tasting notes. Linked to every brew."),
        .init(symbol: "arrow.clockwise",
              title: "Repeat what works",
              detail: "Brew this again — exact recipe, one tap."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 60)

                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 76, height: 76)
                            .shadow(color: Theme.accentGlow, radius: 14, y: 8)
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("BeanBook").foregroundStyle(Theme.ink)
                        Text("is a quiet").foregroundStyle(Theme.ink)
                        Text("logbook.").foregroundStyle(Theme.accent)
                    }
                    .font(.system(size: 44, weight: .medium, design: .serif))
                    .tracking(-1.4)
                    .padding(.top, 36)

                    Text("For the coffee you brew at home. No streaks. No social. No scoring algorithm.")
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.ink2)
                        .lineSpacing(4)
                        .frame(maxWidth: 280, alignment: .leading)
                        .padding(.top, 24)
                }
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(features, id: \.self) { f in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.accentSoft)
                                    .frame(width: 36, height: 36)
                                Image(systemName: f.symbol)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(f.title)
                                    .font(Theme.body(15, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(f.detail)
                                    .font(Theme.body(13))
                                    .foregroundStyle(Theme.ink2)
                                    .lineSpacing(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 36)

                Spacer()

                VStack(spacing: 14) {
                    Button(action: onStart) {
                        Text("Start brewing")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primaryPill)

                    Eyebrow("Made for solo coffee nerds")
                        .tracking(1.4)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
            }
        }
    }
}

#Preview {
    OnboardingView(onStart: {})
}
