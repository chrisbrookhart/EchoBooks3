//
//  SubscriptionManager.swift
//  EchoBooks3
//
//  Manages subscription status and purchases using StoreKit 2.
//

import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    // MARK: - Properties
    
    /// Current subscription status
    @Published var isSubscribed: Bool = false
    
    /// Subscription product identifier
    private let subscriptionProductID = "com.echobooks.subscription" // TODO: Update with actual product ID
    
    /// Cached subscription product
    private var subscriptionProduct: Product?
    
    /// Current subscription status
    private var currentEntitlements: [Product.SubscriptionInfo.Status] = []
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkSubscriptionStatus()
            await observeTransactionUpdates()
        }
    }
    
    // MARK: - Subscription Status
    
    /// Checks the current subscription status
    /// Won't crash if StoreKit is not configured - just returns false
    func checkSubscriptionStatus() async {
        do {
            // Check for active subscription entitlements
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == subscriptionProductID {
                        // Check if subscription is still active
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date() {
                            isSubscribed = true
                            return
                        }
                    }
                }
            }
            
            // Check subscription status
            // This will return empty array if product doesn't exist (StoreKit not configured)
            let products = try await Product.products(for: [subscriptionProductID])
            if let product = products.first {
                subscriptionProduct = product
                
                // Check subscription status using StoreKit 2 API
                if let subscription = product.subscription {
                    let statuses = try await subscription.status
                    for status in statuses {
                        // Check if subscription is in an active state
                        if status.state == .subscribed ||
                           status.state == .inGracePeriod ||
                           status.state == .inBillingRetryPeriod {
                            isSubscribed = true
                            return
                        }
                        // Otherwise, subscription is expired, revoked, or in another inactive state
                    }
                }
            } else {
                // Product not found - StoreKit not configured yet
                print("⚠️ SubscriptionManager: Subscription product not found in StoreKit")
                print("   This is expected if App Store Connect is not set up yet.")
            }
            
            isSubscribed = false
        } catch {
            print("⚠️ SubscriptionManager: StoreKit not configured or error checking status: \(error.localizedDescription)")
            print("   App will continue to work - subscription features will be disabled.")
            // Don't crash - just set to false
            isSubscribed = false
        }
    }
    
    // MARK: - Purchase Subscription
    
    /// Purchases a subscription
    func purchaseSubscription() async throws {
        // Get product if we don't have it cached
        if subscriptionProduct == nil {
            let products = try await Product.products(for: [subscriptionProductID])
            guard let product = products.first else {
                throw SubscriptionError.productNotFound
            }
            subscriptionProduct = product
        }
        
        guard let product = subscriptionProduct else {
            throw SubscriptionError.productNotFound
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Transaction verified, grant subscription
                    await transaction.finish()
                    await checkSubscriptionStatus()
                case .unverified(_, let error):
                    throw SubscriptionError.verificationFailed(error)
                }
            case .userCancelled:
                throw SubscriptionError.userCancelled
            case .pending:
                throw SubscriptionError.purchasePending
            @unknown default:
                throw SubscriptionError.unknownError
            }
        } catch {
            if let subscriptionError = error as? SubscriptionError {
                throw subscriptionError
            }
            throw SubscriptionError.purchaseFailed(error)
        }
    }
    
    // MARK: - Restore Purchases
    
    /// Restores previous purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubscriptionStatus()
    }
    
    // MARK: - Transaction Observation
    
    /// Observes transaction updates for subscription changes
    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                if transaction.productID == subscriptionProductID {
                    await transaction.finish()
                    await checkSubscriptionStatus()
                }
            }
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed(Error)
    case userCancelled
    case purchasePending
    case purchaseFailed(Error)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        case .verificationFailed(let error):
            return "Subscription verification failed: \(error.localizedDescription)"
        case .userCancelled:
            return "Purchase was cancelled."
        case .purchasePending:
            return "Purchase is pending. Please wait for it to complete."
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

