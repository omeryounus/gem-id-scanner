import SwiftUI
import StoreKit

/// Screen 8: Pro Subscription Paywall View
///
/// Features clean subscription tiers (Monthly, Annual with 3-day trial, Lifetime pass),
/// transparent billing disclosure, feature matrix, restore purchases, and StoreKit 2 integration.
public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var allowance: ScanAllowanceManager
    
    @State private var selectedTier: SubscriptionTier = .annual
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var showSuccessAlert = false
    @State private var isProcessing = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.16),
                        Color(red: 0.05, green: 0.06, blue: 0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Badge & Hero Icon
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.amberGold.opacity(0.35), Color.clear],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.amberGold, Color.white],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 6) {
                                Text("UNLOCK GEM ID PRO")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.amberGold)
                                    .tracking(2)
                                
                                Text("Unlimited Mineralogy & Gem ID")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("Identify specimens across our curated catalog without daily scan or collection limits.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Feature Matrix Cards
                        VStack(spacing: 12) {
                            ProFeatureRow(
                                icon: "infinity",
                                title: "Unlimited AI Mineral Scans",
                                description: "Scan as many specimens as you want with no daily caps."
                            )
                            ProFeatureRow(
                                icon: "tray.full.fill",
                                title: "Unlimited Specimen Vault",
                                description: "Expand your personal collection beyond the 20-item free limit."
                            )
                            ProFeatureRow(
                                icon: "wand.and.stars",
                                title: "Diagnostic Lookalike Tests",
                                description: "Full access to streak, hardness, UV fluorescence, and cleavage separation guides."
                            )
                            ProFeatureRow(
                                icon: "square.and.arrow.up.fill",
                                title: "Export Specimen Certificates",
                                description: "Generate beautiful custom share cards for field notes and specimen documentation."
                            )
                            ProFeatureRow(
                                icon: "bolt.horizontal.fill",
                                title: "Hybrid Identification",
                                description: "Apple Intelligence ranks the stone on this iPhone. Uncertain photos go to Gemini through Firebase AI Logic."
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // Subscription Tiers Selection
                        VStack(spacing: 12) {
                            ForEach(SubscriptionTier.allCases) { tier in
                                SubscriptionTierCard(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    onSelect: { selectedTier = tier }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Transparent Billing Disclaimer
                        VStack(spacing: 6) {
                            if selectedTier == .annual {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.emeraldGreen)
                                    Text("3-Day Free Trial included. Cancel anytime in Apple ID Settings.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            } else if selectedTier == .lifetime {
                                HStack(spacing: 6) {
                                    Image(systemName: "infinity.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.amberGold)
                                    Text("Pay once. Never charged again. All future updates included.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 13))
                                        .foregroundColor(.cyan)
                                    Text("Monthly subscription auto-renews. Cancel anytime.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Purchase Button
                        VStack(spacing: 12) {
                            Button(action: {
                                handlePurchase()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.amberGold, Color(red: 0.95, green: 0.50, blue: 0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 56)
                                        .shadow(color: Color.amberGold.opacity(0.35), radius: 12, y: 4)
                                    
                                    if isProcessing || storeKit.purchaseInProgress {
                                        ProgressView()
                                            .tint(.black)
                                    } else {
                                        HStack(spacing: 8) {
                                            Text(ctaButtonTitle)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundColor(.black)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                            .disabled(isProcessing || storeKit.purchaseInProgress)
                            .padding(.horizontal, 16)
                            
                            // Restore & Legal Footer Links
                            HStack(spacing: 16) {
                                Button("Restore Purchases") {
                                    handleRestore()
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Button("Terms of Service") {
                                    showTermsSheet = true
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Button("Privacy Policy") {
                                    showPrivacySheet = true
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                    }
                }
                
                // Error Banner Toast
                if let error = storeKit.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.coralRed.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 80)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .alert("Pro Unlocked!", isPresented: $showSuccessAlert) {
                Button("Let's Rock!", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Thank you for supporting Gem ID Scanner. Unlimited scans and full mineral databases are now active.")
            }
            .sheet(isPresented: $showTermsSheet) {
                NavigationStack {
                    LegalDocumentView(
                        title: "Terms of Service",
                        content: LegalDocumentContent.terms
                    )
                }
            }
            .sheet(isPresented: $showPrivacySheet) {
                NavigationStack {
                    LegalDocumentView(
                        title: "Privacy Policy",
                        content: LegalDocumentContent.privacy
                    )
                }
            }
        }
    }
    
    private var ctaButtonTitle: String {
        switch selectedTier {
        case .annual:
            return "Start 3-Day Free Trial"
        case .monthly:
            return "Start Monthly Subscription"
        case .lifetime:
            return "Get Lifetime Access"
        }
    }
    
    private func handlePurchase() {
        Task {
            isProcessing = true
            let success = await storeKit.purchase(tier: selectedTier)
            isProcessing = false
            if success {
                allowance.updateProStatus(isPro: true)
                showSuccessAlert = true
            }
        }
    }
    
    private func handleRestore() {
        Task {
            isProcessing = true
            await storeKit.restorePurchases()
            isProcessing = false
            if storeKit.isProPurchased {
                allowance.updateProStatus(isPro: true)
                showSuccessAlert = true
            }
        }
    }
}

// MARK: - Subviews

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.amberGold.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.amberGold)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SubscriptionTierCard: View {
    @EnvironmentObject private var storeKit: StoreKitService
    
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let badge = tier.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.amberGold)
                                .clipShape(Capsule())
                        }
                        
                        Text(tier.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(tier.savingsSubtext)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(storeKit.displayPrice(for: tier))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .amberGold : .white)
                        
                        ZStack {
                            Circle()
                                .stroke(isSelected ? Color.amberGold : Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 22, height: 22)
                            
                            if isSelected {
                                Circle()
                                    .fill(Color.amberGold)
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.amberGold.opacity(0.12) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.amberGold : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
