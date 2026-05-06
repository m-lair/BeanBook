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
    // Free
    case forest

    // Pro — existing
    case ocean
    case mocha

    // Pro — new (warms)
    case latte
    case honey
    case cascara
    case espresso

    // Pro — new (darks)
    case graphite

    // Pro — new (botanicals)
    case sage
    case plum

    var id: String { rawValue }

    static func canonical(rawValue: String) -> PaletteID? {
        switch rawValue {
        case "cocoa": .mocha
        case "slate": .ocean
        case "noir": .graphite
        default: PaletteID(rawValue: rawValue)
        }
    }
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

    static let espresso = Palette(
        id: .espresso,
        name: "Espresso",
        isPro: true,
        background: Color(hex: "F6F0E6"),
        card: Color(hex: "FFFAF2"),
        ink: Color(hex: "1B1108"),
        ink2: Color(hex: "5A4332"),
        ink3: Color(hex: "9A8472"),
        ink4: Color(hex: "D2C2AE"),
        rule: Color(hex: "E1D2BE"),
        accent: Color(hex: "3A2415"),
        accentSoft: Color(hex: "E5D5C0"),
        accentGlow: Color(hex: "3A2415").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "7A5A2A")
    )

    static let latte = Palette(
        id: .latte,
        name: "Latte",
        isPro: true,
        background: Color(hex: "FBF4ED"),
        card: Color(hex: "FFFAF4"),
        ink: Color(hex: "2A1A12"),
        ink2: Color(hex: "7A5E4A"),
        ink3: Color(hex: "B59B85"),
        ink4: Color(hex: "DDC8B4"),
        rule: Color(hex: "EAD8C4"),
        accent: Color(hex: "A35E4A"),
        accentSoft: Color(hex: "F0DCCC"),
        accentGlow: Color(hex: "A35E4A").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "8A6A40")
    )

    static let cascara = Palette(
        id: .cascara,
        name: "Cascara",
        isPro: true,
        background: Color(hex: "FAF1E4"),
        card: Color(hex: "FFF8EC"),
        ink: Color(hex: "2B1A0E"),
        ink2: Color(hex: "7E5A38"),
        ink3: Color(hex: "B49274"),
        ink4: Color(hex: "DCC0A0"),
        rule: Color(hex: "EAD3B0"),
        accent: Color(hex: "B05A1E"),
        accentSoft: Color(hex: "F0D9B4"),
        accentGlow: Color(hex: "B05A1E").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "9A6A22")
    )

    static let honey = Palette(
        id: .honey,
        name: "Honey",
        isPro: true,
        background: Color(hex: "FBF6E6"),
        card: Color(hex: "FFFBEE"),
        ink: Color(hex: "22180A"),
        ink2: Color(hex: "6E5A2A"),
        ink3: Color(hex: "A89770"),
        ink4: Color(hex: "D2C292"),
        rule: Color(hex: "E5D7A8"),
        accent: Color(hex: "8A6A12"),
        accentSoft: Color(hex: "F1E4B4"),
        accentGlow: Color(hex: "8A6A12").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "7A5E1A")
    )

    static let graphite = Palette(
        id: .graphite,
        name: "Graphite",
        isPro: true,
        background: Color(hex: "EAE7E2"),
        card: Color(hex: "F4F1EC"),
        ink: Color(hex: "14171A"),
        ink2: Color(hex: "50545A"),
        ink3: Color(hex: "8A8E94"),
        ink4: Color(hex: "BCBFC4"),
        rule: Color(hex: "D2D4D8"),
        accent: Color(hex: "3E4148"),
        accentSoft: Color(hex: "D9DCE1"),
        accentGlow: Color(hex: "3E4148").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "4A6A4A")
    )

    static let sage = Palette(
        id: .sage,
        name: "Sage",
        isPro: true,
        background: Color(hex: "F4F2EA"),
        card: Color(hex: "FBFAF2"),
        ink: Color(hex: "1A1F18"),
        ink2: Color(hex: "56604E"),
        ink3: Color(hex: "8A9482"),
        ink4: Color(hex: "C0C8B6"),
        rule: Color(hex: "D6DCC8"),
        accent: Color(hex: "6E7E54"),
        accentSoft: Color(hex: "DEE4CC"),
        accentGlow: Color(hex: "6E7E54").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "7A8A52")
    )

    static let plum = Palette(
        id: .plum,
        name: "Plum",
        isPro: true,
        background: Color(hex: "F1EDEC"),
        card: Color(hex: "F9F6F4"),
        ink: Color(hex: "1A1216"),
        ink2: Color(hex: "5C4E54"),
        ink3: Color(hex: "928288"),
        ink4: Color(hex: "C2B6BC"),
        rule: Color(hex: "D8CED2"),
        accent: Color(hex: "5A2E48"),
        accentSoft: Color(hex: "E2D2D8"),
        accentGlow: Color(hex: "5A2E48").opacity(0.22),
        error: Color(hex: "B5293A"),
        success: Color(hex: "7A5A48")
    )

    /// Display order for the picker. Grouped by hue family rather than by
    /// the `PaletteID` declaration order — `mocha` and `ocean` are original
    /// Pro palettes that flow into the warm and cool groups respectively.
    static let all: [Palette] = [
        // Free
        .forest,
        // Warms
        .latte, .honey, .cascara, .mocha, .espresso,
        // Cools
        .ocean,
        // Darks
        .graphite,
        // Botanicals
        .sage, .plum,
    ]

    static func with(id: PaletteID) -> Palette {
        switch id {
        case .forest:   .forest
        case .ocean:    .ocean
        case .mocha:    .mocha
        case .latte:    .latte
        case .honey:    .honey
        case .cascara:  .cascara
        case .espresso: .espresso
        case .graphite: .graphite
        case .sage:     .sage
        case .plum:     .plum
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
