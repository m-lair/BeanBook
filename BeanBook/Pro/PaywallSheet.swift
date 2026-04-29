import SwiftUI
import StoreKit

/// One-time purchase paywall for BeanBook Pro.
struct PaywallSheet: View {
    @Environment(ProEntitlement.self) private var pro
    @Environment(\.dismiss) private var dismiss

    /// Optional context line — e.g. "You've reached the free brew limit."
    var headline: String? = nil

    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://example.com/beanbook/privacy")!

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    bullets.padding(.top, 32)
                    purchaseSection.padding(.top, 36)
                    footer.padding(.top, 24)
                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .foregroundStyle(Theme.ink2)
            }
        }
        .task {
            if pro.product == nil {
                await pro.start()
            }
        }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 76, height: 76)
                Image(systemName: "cup.and.heat.waves.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 24)

            Eyebrow("BeanBook Pro")
                .padding(.top, 24)

            Text("One purchase.\nYours forever.")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)

            valuePropChips
                .padding(.top, 16)

            if let headline {
                Text(headline)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink2)
                    .padding(.top, 16)
            }
        }
    }

    private var valuePropChips: some View {
        FlowLayout(spacing: 6) {
            ValueChip(symbol: "checkmark", text: "Pay once")
            ValueChip(symbol: "xmark.circle", text: "No subscription")
            ValueChip(symbol: "sparkles", text: "Future features included")
        }
    }

    // MARK: - Bullets

    private var bullets: some View {
        VStack(alignment: .leading, spacing: 0) {
            BulletRow(icon: "infinity",
                      title: "Unlimited bags, brews & recipes",
                      detail: "Free tier caps lifted.")
            BulletRow(icon: "heart.circle",
                      title: "Support indie development",
                      detail: "BeanBook is built by one person — thank you.")
            BulletRow(icon: "sparkles",
                      title: "Future Pro features included",
                      detail: "Stats, export, themes — all yours when they ship.")
        }
    }

    // MARK: - Purchase

    @ViewBuilder
    private var purchaseSection: some View {
        if pro.isPro {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                Text("You have Pro.")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(Theme.ink)
                Text("Thanks for supporting BeanBook.")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink2)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                Button {
                    Task { await pro.purchase() }
                } label: {
                    Text(buyLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryPill)
                .disabled(isBusy)

                Button {
                    Task { await pro.restore() }
                } label: {
                    Text("Restore Purchases")
                        .font(Theme.body(14, weight: .medium))
                        .foregroundStyle(Theme.ink2)
                }
                .disabled(isBusy)

                if case .failed(let message) = pro.purchaseState {
                    Text(message)
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.error)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var buyLabel: String {
        switch pro.purchaseState {
        case .loading:    return "Loading…"
        case .purchasing: return "Purchasing…"
        default:
            if let price = pro.product?.displayPrice {
                return "Unlock Pro · \(price) once"
            }
            return "Unlock Pro"
        }
    }

    private var isBusy: Bool {
        switch pro.purchaseState {
        case .loading, .purchasing: return true
        default: return false
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Text("One-time purchase · No subscription · Family Sharing supported")
                .font(Theme.body(12, weight: .medium))
                .foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 18) {
                Link("Terms of Use", destination: Self.termsURL)
                Text("·").foregroundStyle(Theme.ink4)
                Link("Privacy Policy", destination: Self.privacyURL)
            }
            .font(Theme.body(12))
            .foregroundStyle(Theme.ink3)
        }
    }
}

private struct ValueChip: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(Theme.body(11, weight: .semibold))
                .tracking(0.3)
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.accentSoft, in: .capsule)
        .overlay(Capsule().stroke(Theme.accent.opacity(0.18), lineWidth: 0.5))
    }
}

private struct BulletRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 0) {
            HairRule()
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24, alignment: .center)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.body(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.ink2)
                        .lineSpacing(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
        }
    }
}
