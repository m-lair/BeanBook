import Foundation

@MainActor
@Observable
final class CatalogService {
    private(set) var beans: [CatalogBean] = []

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "beans_catalog", withExtension: "json") else {
            beans = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            beans = try JSONDecoder().decode([CatalogBean].self, from: data)
        } catch {
            print("CatalogService: failed to load catalog — \(error)")
            beans = []
        }
    }

    var roastLevels: [RoastLevel] {
        Array(Set(beans.map(\.roastLevel))).sorted { $0.displayName < $1.displayName }
    }

    var origins: [String] {
        Array(Set(beans.map(\.origin))).sorted()
    }
}
