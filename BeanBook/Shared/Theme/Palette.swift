import SwiftUI

/// A complete color palette. All `Theme.*` color accessors resolve through
/// `themeStore.palette` so that mutating the store invalidates dependent
/// views via the Observation framework.
///
/// Palettes are intentionally light-mode only. Dark mode is out of scope.
struct Palette: Equatable, Sendable {
    let id: PaletteID
    let name: String
    let isPro: Bool

    // Surfaces
    let background: Color
    let card: Color

    // Neutrals (text + dividers)
    let ink: Color
    let ink2: Color
    let ink3: Color
    let ink4: Color
    let rule: Color

    // Brand
    let accent: Color
    let accentSoft: Color
    let accentGlow: Color

    // Semantic
    let error: Color
    let success: Color
}

enum PaletteID: String, CaseIterable, Identifiable, Sendable {
    case forest
    case ocean
    case mocha

    var id: String { rawValue }
}

extension Palette {
    static let forest = Palette(
        id: .forest,
        name: "Forest",
        isPro: false,
        background: Color(hex: "FAFAF7"),
        card: Color.white,
        ink: Color(hex: "0F1110"),
        ink2: Color(hex: "6B6B66"),
        ink3: Color(hex: "A8A8A2"),
        ink4: Color(hex: "D8D5CD"),
        rule: Color(hex: "E8E5DD"),
        accent: Color(hex: "2D4A2B"),
        accentSoft: Color(hex: "DFE7DD"),
        accentGlow: Color(hex: "2D4A2B").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "5A7A3A")
    )

    static let ocean = Palette(
        id: .ocean,
        name: "Ocean",
        isPro: true,
        background: Color(hex: "F4F7F8"),
        card: Color.white,
        ink: Color(hex: "0E1A23"),
        ink2: Color(hex: "5C6B74"),
        ink3: Color(hex: "9AA6AE"),
        ink4: Color(hex: "CFD7DD"),
        rule: Color(hex: "DEE5E9"),
        accent: Color(hex: "1F5A6E"),
        accentSoft: Color(hex: "D6E4EA"),
        accentGlow: Color(hex: "1F5A6E").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "3F7E84")
    )

    static let mocha = Palette(
        id: .mocha,
        name: "Mocha",
        isPro: true,
        background: Color(hex: "F8F2EA"),
        card: Color(hex: "FFFBF5"),
        ink: Color(hex: "2A1B12"),
        ink2: Color(hex: "705946"),
        ink3: Color(hex: "A8917C"),
        ink4: Color(hex: "D8C8B6"),
        rule: Color(hex: "E8DCC8"),
        accent: Color(hex: "5C3320"),
        accentSoft: Color(hex: "EBDDC9"),
        accentGlow: Color(hex: "5C3320").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "8A6A1F")
    )

    static let all: [Palette] = [.forest, .ocean, .mocha]

    static func with(id: PaletteID) -> Palette {
        switch id {
        case .forest: .forest
        case .ocean:  .ocean
        case .mocha:  .mocha
        }
    }
}

/// Process-wide source of truth for the active palette. Color accessors on
/// `Theme` read through this; mutating `palette` invalidates any SwiftUI
/// view that read a token during its last body evaluation.
@MainActor
@Observable
final class ThemeStore {
    var palette: Palette = .forest
}

@MainActor
let themeStore = ThemeStore()
