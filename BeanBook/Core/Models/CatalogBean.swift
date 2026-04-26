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

    var url: URL? { URL(string: roasterURL) }
}
