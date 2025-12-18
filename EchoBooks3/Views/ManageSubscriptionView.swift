//
//  ManageSubscriptionView.swift
//  EchoBooks3
//
//  View for managing subscription status, purchasing subscriptions, and restoring purchases.
//

import SwiftUI

struct ManageSubscriptionView: View {
    // MARK: - State Objects
    
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    // MARK: - State
    
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Subscription Status
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Subscription Status")
                        .font(DesignSystem.Typography.h2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        Image(systemName: subscriptionManager.isSubscribed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(subscriptionManager.isSubscribed ? .green : .red)
                        
                        Text(subscriptionManager.isSubscribed ? "Active" : "Not Subscribed")
                            .font(DesignSystem.Typography.h3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.card)
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Subscription Benefits
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Subscription Benefits")
                        .font(DesignSystem.Typography.h2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        BenefitRow(icon: "book.fill", text: "Access to all premium books")
                        BenefitRow(icon: "globe", text: "Download books in multiple languages")
                        BenefitRow(icon: "arrow.down.circle.fill", text: "Unlimited downloads")
                        BenefitRow(icon: "star.fill", text: "Early access to new content")
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                
                // Action Buttons
                VStack(spacing: DesignSystem.Spacing.md) {
                    if !subscriptionManager.isSubscribed {
                        Button(action: {
                            Task {
                                await purchaseSubscription()
                            }
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(isPurchasing ? "Processing..." : "Subscribe Now")
                                    .font(DesignSystem.Typography.button)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
                            .background(isPurchasing ? DesignSystem.Colors.primary.opacity(0.7) : DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .shadow(DesignSystem.Shadow.small)
                        }
                        .disabled(isPurchasing || isRestoring)
                    }
                    
                    Button(action: {
                        Task {
                            await restorePurchases()
                        }
                    }) {
                        Text(isRestoring ? "Restoring..." : "Restore Purchases")
                            .font(DesignSystem.Typography.button)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                            )
                    }
                    .disabled(isPurchasing || isRestoring)
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                
                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
        }
        .navigationTitle("Manage Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscriptionManager.checkSubscriptionStatus()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Actions
    
    private func purchaseSubscription() async {
        isPurchasing = true
        errorMessage = nil
        
        do {
            try await subscriptionManager.purchaseSubscription()
            // Status will be updated automatically via @Published
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isPurchasing = false
    }
    
    private func restorePurchases() async {
        isRestoring = true
        errorMessage = nil
        
        do {
            try await subscriptionManager.restorePurchases()
            // Status will be updated automatically via @Published
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isRestoring = false
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 30)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
    }
}

struct ManageSubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ManageSubscriptionView()
        }
    }
}
