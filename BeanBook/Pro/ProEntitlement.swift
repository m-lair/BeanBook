import Foundation
import StoreKit

/// Read-only seam used by gated stores so tests can inject a stub without
/// touching StoreKit. Real entitlement is `ProEntitlement`.
@MainActor
protocol ProEntitlementProviding: AnyObject {
    var isPro: Bool { get }
}

/// One-time non-consumable "BeanBook Pro" entitlement, backed by StoreKit 2.
///
/// Lifecycle:
/// - `start()` loads the product, refreshes current entitlements, and spawns a
///   long-lived `Transaction.updates` listener. Call once at app launch.
/// - `purchase()` runs the StoreKit purchase flow and finishes the transaction.
/// - `restore()` calls `AppStore.sync()` (used by the "Restore Purchases" button).
///
/// Offline launch: the last-known `isPro` is mirrored to `UserDefaults` so
/// gating works in airplane mode and is revalidated when entitlements refresh.
@MainActor
@Observable
final class ProEntitlement: ProEntitlementProviding {
    static let productID = "com.beanbook.pro.lifetime"
    private static let cacheKey = "pro.isProCached"

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
    }

    private(set) var isPro: Bool
    private(set) var product: Product?
    private(set) var purchaseState: PurchaseState = .idle

    private var updatesTask: Task<Void, Never>?

    init() {
        self.isPro = UserDefaults.standard.bool(forKey: Self.cacheKey)
    }

    /// Load the product and refresh entitlements. Spawns the updates listener.
    func start() async {
        purchaseState = .loading
        await loadProduct()
        await refreshEntitlements()
        purchaseState = .idle

        updatesTask?.cancel()
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                await self.handle(update)
            }
        }
    }

    func purchase() async {
        guard let product else {
            await loadProduct()
            guard product != nil else {
                purchaseState = .failed("Product unavailable.")
                return
            }
            await purchase()
            return
        }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let txn = try? checkVerified(verification) {
                    await txn.finish()
                    setPro(true)
                    purchaseState = .success
                } else {
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = .idle
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
        } catch {
            self.product = nil
        }
    }

    private func refreshEntitlements() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if let txn = try? checkVerified(result),
               txn.productID == Self.productID,
               txn.revocationDate == nil {
                found = true
            }
        }
        setPro(found)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard let txn = try? checkVerified(result) else { return }
        if txn.productID == Self.productID {
            setPro(txn.revocationDate == nil)
        }
        await txn.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error): throw error
        }
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
