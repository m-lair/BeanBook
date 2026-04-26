import Foundation

enum BrewMethod: String, CaseIterable, Codable, Identifiable, Hashable {
    case espresso
    case pourOver
    case frenchPress
    case aeroPress
    case mokaPot
    case coldBrew

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .espresso: "Espresso"
        case .pourOver: "Pour Over"
        case .frenchPress: "French Press"
        case .aeroPress: "AeroPress"
        case .mokaPot: "Moka Pot"
        case .coldBrew: "Cold Brew"
        }
    }

    var symbol: String {
        switch self {
        case .espresso: "cup.and.saucer.fill"
        case .pourOver: "drop.fill"
        case .frenchPress: "cylinder.fill"
        case .aeroPress: "circle.hexagonpath.fill"
        case .mokaPot: "flame.fill"
        case .coldBrew: "snowflake"
        }
    }

    /// Default dose in grams of dry coffee.
    var defaultDose: Double {
        switch self {
        case .espresso: 18
        case .pourOver: 22
        case .frenchPress: 30
        case .aeroPress: 15
        case .mokaPot: 18
        case .coldBrew: 80
        }
    }

    /// Default yield in grams of liquid out (or water in for immersion).
    var defaultYield: Double {
        switch self {
        case .espresso: 36
        case .pourOver: 350
        case .frenchPress: 500
        case .aeroPress: 240
        case .mokaPot: 80
        case .coldBrew: 800
        }
    }

    /// Default brew time in seconds.
    var defaultTimeSeconds: Int {
        switch self {
        case .espresso: 30
        case .pourOver: 210
        case .frenchPress: 240
        case .aeroPress: 90
        case .mokaPot: 300
        case .coldBrew: 12 * 3600
        }
    }

    /// Default water temperature in °C, or nil if temp doesn't apply.
    var defaultWaterTempC: Double? {
        switch self {
        case .espresso: nil      // boiler-controlled, not user-set
        case .pourOver: 94
        case .frenchPress: 96
        case .aeroPress: 85
        case .mokaPot: nil       // stovetop-controlled
        case .coldBrew: nil      // cold/ambient
        }
    }

    var usesTemperature: Bool { defaultWaterTempC != nil }

    /// Label for the "yield" field — espresso is the liquid OUT, pour-over is water IN.
    var yieldLabel: String {
        switch self {
        case .espresso, .mokaPot: "Yield (g)"
        default: "Water (g)"
        }
    }

    var doseLabel: String { "Dose (g)" }

    var timeLabel: String {
        self == .coldBrew ? "Steep time" : "Brew time"
    }

    /// Sensible numeric range for the dose stepper / validation.
    var doseRange: ClosedRange<Double> {
        switch self {
        case .espresso: 12...25
        case .pourOver: 10...60
        case .frenchPress: 20...80
        case .aeroPress: 10...30
        case .mokaPot: 10...30
        case .coldBrew: 40...200
        }
    }

    var yieldRange: ClosedRange<Double> {
        switch self {
        case .espresso: 20...80
        case .pourOver: 100...700
        case .frenchPress: 200...1000
        case .aeroPress: 80...400
        case .mokaPot: 40...200
        case .coldBrew: 300...2000
        }
    }
}
