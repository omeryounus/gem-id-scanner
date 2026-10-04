import Foundation
import StoreKit
import SwiftUI

public enum SubscriptionTier: String, CaseIterable, Identifiable, Sendable {
    case monthly = "com.gemidscanner.pro.monthly"
    case annual = "com.gemidscanner.pro.annual"
    case lifetime = "com.gemidscanner.pro.lifetime"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .monthly: return "Monthly Pro"
        case .annual: return "Annual Pro"
        case .lifetime: return "Lifetime Pass"
        }
    }
    
    public var priceString: String {
        switch self {
        case .monthly: return "$4.99 / month"
        case .annual: return "$29.99 / year"
        case .lifetime: return "$69.99 once"
        }
    }
    
    public var badge: String? {
        switch self {
        case .annual: return "BEST VALUE • 3-DAY FREE TRIAL"
        case .lifetime: return "PAY ONCE FOREVER"
        case .monthly: return nil
        }
    }
    
    public var savingsSubtext: String {
        switch self {
        case .annual: return "$2.50/mo • Billed $29.99/yr after 3-day trial"
        case .monthly: return "Flexible month-to-month access"
        case .lifetime: return "Never pay again. Includes all future catalog updates"
        }
    }
}

/// StoreKit 2 native in-app purchase and subscription manager.
///
/// Handles Monthly, Annual (with 3-day trial), and Lifetime purchases,
/// entitlement verification, transaction listener updates, and purchase restoration.
@MainActor
public final class StoreKitService: ObservableObject {
    public static let shared = StoreKitService()
    
    @Published public var isProPurchased: Bool = false
    @Published public var availableProducts: [Product] = []
    @Published public var purchaseInProgress: Bool = false
    @Published public var errorMessage: String?
    
    private var updatesTask: Task<Void, Never>?
    
    public init() {
        // Check initial entitlements
        Task {
            await checkCurrentEntitlements()
            await fetchProducts()
        }
        
        // Listen for external transaction updates
        updatesTask = listenForTransactions()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    public func fetchProducts() async {
        let productIDs = Set(SubscriptionTier.allCases.map { $0.rawValue })
        do {
            let products = try await Product.products(for: productIDs)
            self.availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            self.errorMessage = "Failed to load subscription products from App Store: \(error.localizedDescription)"
        }
    }
    
    public func purchase(tier: SubscriptionTier) async -> Bool {
        purchaseInProgress = true
        errorMessage = nil
        
        guard let product = availableProducts.first(where: { $0.id == tier.rawValue }) else {
            // For simulator / preview without StoreKit configuration file, simulate success
            #if DEBUG
            self.isProPurchased = true
            ScanAllowanceManager.shared.updateProStatus(isPro: true)
            purchaseInProgress = false
            return true
            #else
            self.errorMessage = "Product currently unavailable in App Store."
            purchaseInProgress = false
            return false
            #endif
        }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkCurrentEntitlements()
                purchaseInProgress = false
                return true
            case .userCancelled:
                purchaseInProgress = false
                return false
            case .pending:
                purchaseInProgress = false
                return false
            @unknown default:
                purchaseInProgress = false
                return false
            }
        } catch {
            self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            purchaseInProgress = false
            return false
        }
    }
    
    public func restorePurchases() async {
        purchaseInProgress = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        purchaseInProgress = false
    }
    
    public func checkCurrentEntitlements() async {
        var hasActivePro = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if SubscriptionTier.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        hasActivePro = true
                    }
                }
            } catch {
                continue
            }
        }
        
        self.isProPurchased = hasActivePro
        ScanAllowanceManager.shared.updateProStatus(isPro: hasActivePro)
    }
    
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.checkCurrentEntitlements()
                } catch {
                    continue
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
