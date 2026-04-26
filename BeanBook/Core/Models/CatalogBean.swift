import Foundation

struct CatalogBean: Codable, Identifiable, Hashable {
    let id: String
    let roaster: String
    let name: String
    let origin: String
    let process: ProcessMethod
    let roastLevel: RoastLevel
    let tastingNotes: [String]
    let description: String
    let roasterURL: String

    // Roaster headquarters — used for the "Near you" section in Shop.
    // All optional so untagged catalog entries simply don't appear in Near You.
    var roasterCity: String? = nil
    var roasterRegion: String? = nil
    var roasterCountry: String? = nil
    var roasterLat: Double? = nil
    var roasterLng: Double? = nil

    var url: URL? { URL(string: roasterURL) }

    var roasterLocationLabel: String? {
        switch (roasterCity, roasterRegion) {
        case let (city?, region?): return "\(city), \(region)"
        case let (city?, nil):     return city
        default:                   return nil
        }
    }
}
