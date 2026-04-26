import Foundation

enum RoastLevel: String, CaseIterable, Codable, Identifiable, Hashable {
    case light, mediumLight, medium, mediumDark, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: "Light"
        case .mediumLight: "Medium-Light"
        case .medium: "Medium"
        case .mediumDark: "Medium-Dark"
        case .dark: "Dark"
        }
    }
}

enum ProcessMethod: String, CaseIterable, Codable, Identifiable, Hashable {
    case washed, natural, honey, anaerobic, decaf, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .washed: "Washed"
        case .natural: "Natural"
        case .honey: "Honey"
        case .anaerobic: "Anaerobic"
        case .decaf: "Decaf"
        case .other: "Other"
        }
    }
}
