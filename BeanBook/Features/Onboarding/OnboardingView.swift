import SwiftUI
import SwiftData

/// First-run onboarding — two-step: intro → bag handoff.
/// Step 2 lets the user seed their first bag from the catalog or via NewBagSheet,
/// so the rest of the app (Recent shots strip, prefill, bag picker) is meaningful from brew #1.
struct OnboardingView: View {
    let onStart: () -> Void

    @Query private var bags: [Bag]

    @State private var step: Int = 0
    @State private var showAddBag = false
    @State private var showShop = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
              detail: "Once you log a shot, brew it again with one tap."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                switch step {
                case 0: introStep
                default: beansStep
                }
            }
            .id(step)
            .transition(reduceMotion ? .identity : .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
        }
        .animation(.snappy(duration: 0.32), value: step)
        .sheet(isPresented: $showAddBag) {
            NewBagSheet()
        }
        .sheet(isPresented: $showShop) {
            NavigationStack { ShopView() }
        }
    }

    // MARK: - Step 0: Intro

    private var introStep: some View {
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
                Button {
                    withAnimation(.snappy(duration: 0.32)) { step = 1 }
                } label: {
                    Text("Get started")
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

    // MARK: - Step 1: Beans handoff

    private var beansStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 80)

            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Step 2 of 2")
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 0) {
                    Text("First, the").foregroundStyle(Theme.ink)
                    Text("beans.").foregroundStyle(Theme.accent)
                }
                .font(.system(size: 40, weight: .medium, design: .serif))
                .tracking(-1.2)

                Text("Brews are linked to bags so origin, roast date, and tasting notes follow each shot. Add what you have on hand — you can change this anytime.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                OnboardingChoiceRow(
                    symbol: "plus.circle.fill",
                    title: "Add a bag I own",
                    detail: bags.isEmpty ? "Brand, origin, roast date." : "\(bags.count) added · tap to add another",
                    accent: true,
                    action: { showAddBag = true }
                )
                OnboardingChoiceRow(
                    symbol: "sparkles",
                    title: "Browse roasters",
                    detail: "Curated bags from indie roasters.",
                    accent: false,
                    action: { showShop = true }
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    onStart()
                } label: {
                    Text(bags.isEmpty ? "Skip for now" : "Start brewing")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryPill)

                if bags.isEmpty {
                    Eyebrow("You can always add bags later")
                        .tracking(1.4)
                        .foregroundStyle(Theme.ink3)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Choice row

private struct OnboardingChoiceRow: View {
    let symbol: String
    let title: String
    let detail: String
    let accent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent ? Theme.accent : Theme.accentSoft)
                        .frame(width: 42, height: 42)
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(accent ? .white : Theme.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.body(16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink2)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink3)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Theme.card, in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.rule, lineWidth: 0.5)
            )
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView(onStart: {})
        .modelContainer(for: [Bag.self, Brew.self, BrewPreset.self], inMemory: true)
}
