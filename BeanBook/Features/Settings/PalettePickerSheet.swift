import SwiftUI

/// Palette picker. Tapping a palette previews it live across the entire app.
/// Saving persists it; closing without saving reverts to the stored palette.
struct PalettePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProEntitlement.self) private var pro

    @AppStorage("paletteID") private var paletteIDRaw: String = PaletteID.forest.rawValue

    @State private var originalID: PaletteID = .forest
    @State private var selectedID: PaletteID = .forest
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    palettesList
                    Spacer().frame(height: 40)
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
                Button("Close") {
                    revertPreview()
                    dismiss()
                }
                .foregroundStyle(Theme.ink2)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { confirm() }
                    .font(Theme.body(15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(selectedID.rawValue == paletteIDRaw)
            }
        }
        .task {
            let storedID = PaletteID.canonical(rawValue: paletteIDRaw) ?? .forest
            if storedID.rawValue != paletteIDRaw {
                paletteIDRaw = storedID.rawValue
            }
            originalID = storedID
            selectedID = storedID
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallSheet(headline: "\(Palette.with(id: selectedID).name) is a Pro palette. Unlock to keep it.")
            }
        }
        .onChange(of: showingPaywall) { _, presenting in
            if !presenting && !pro.isPro {
                revertPreview()
                selectedID = originalID
            }
        }
        .onChange(of: pro.isPro) { _, nowPro in
            if nowPro && showingPaywall {
                showingPaywall = false
                persistSelection(dismissAfterSave: true)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Appearance")
            Text("Palette.")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(Theme.ink)
            Text("Tap to preview live across the app.")
                .font(Theme.body(14))
                .foregroundStyle(Theme.ink2)
        }
        .padding(.bottom, 28)
    }

    private var palettesList: some View {
        VStack(spacing: 14) {
            ForEach(Palette.all, id: \.id) { palette in
                PaletteCard(
                    palette: palette,
                    isSelected: selectedID == palette.id,
                    isLocked: palette.isPro && !pro.isPro,
                    action: { select(palette) }
                )
            }
        }
    }

    // MARK: - Selection / preview / persist

    private func select(_ palette: Palette) {
        selectedID = palette.id
        if !palette.isPro || pro.isPro {
            preview(palette.id)
        }
    }

    private func confirm() {
        let palette = Palette.with(id: selectedID)
        if palette.isPro && !pro.isPro {
            showingPaywall = true
            return
        }
        persistSelection(dismissAfterSave: true)
    }

    private func persistSelection(dismissAfterSave: Bool) {
        paletteIDRaw = selectedID.rawValue
        themeStore.palette = Palette.with(id: selectedID)
        if dismissAfterSave {
            dismiss()
        }
    }

    private func preview(_ id: PaletteID) {
        themeStore.palette = Palette.with(id: id)
    }

    private func revertPreview() {
        if themeStore.palette.id != originalID {
            themeStore.palette = Palette.with(id: originalID)
        }
    }
}

// MARK: - Card

private struct PaletteCard: View {
    let palette: Palette
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                swatch
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(palette.name)
                            .font(.system(size: 20, weight: .medium, design: .serif))
                            .foregroundStyle(Theme.ink)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.ink3)
                        }
                    }
                    Text(palette.isPro ? "Pro palette" : "Included")
                        .font(Theme.body(12, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(palette.isPro ? Theme.accent : Theme.ink3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                } else {
                    Circle()
                        .stroke(Theme.rule, lineWidth: 1)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.rule, lineWidth: isSelected ? 1.5 : 0.5)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(palette.name)\(isLocked ? ", locked" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var swatch: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(palette.background)
                .frame(width: 64, height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(palette.rule, lineWidth: 0.5)
                )
            Circle()
                .fill(palette.accent)
                .frame(width: 26, height: 26)
                .shadow(color: palette.accentGlow, radius: 6, y: 2)
        }
    }
}
