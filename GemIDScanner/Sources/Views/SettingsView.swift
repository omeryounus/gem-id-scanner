import SwiftUI
import SwiftData

/// Screen: App Settings, Subscription Management, Storage, and AI Improvement Opt-in
public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var allowance: ScanAllowanceManager
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    
    @Query private var specimens: [SpecimenRecord]
    
    @AppStorage("GemIDScanner_AutoTorch") private var autoTorch = false
    @AppStorage("GemIDScanner_HapticFeedback") private var hapticFeedback = true
    @AppStorage("GemIDScanner_HighPrecisionCloud") private var highPrecisionCloud = true
    
    @State private var showPaywall = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showClearCacheAlert = false
    @State private var showExportSheet = false
    @State private var exportedDataString: String?
    @State private var cacheClearedToast = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea()
                
                List {
                    // MARK: - Subscription / Pro Status
                    Section {
                        if storeKit.isProPurchased {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.amberGold.opacity(0.18))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.amberGold)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("Gem ID Pro Active")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("PRO")
                                            .font(.system(size: 9, weight: .black, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.amberGold)
                                            .clipShape(Capsule())
                                    }
                                    Text("Unlimited daily scans • Unlimited collection")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.65))
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Free Plan")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("Daily Scans: \(allowance.dailyScansUsed) of \(ScanAllowanceManager.freeDailyScanLimit) used")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Button(action: { showPaywall = true }) {
                                        Text("Upgrade")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 6)
                                            .background(Color.amberGold)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                // Progress Meter
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(allowance.remainingDailyScans > 0 ? Color.cyan : Color.coralRed)
                                            .frame(width: geo.size.width * CGFloat(min(allowance.dailyScansUsed, ScanAllowanceManager.freeDailyScanLimit)) / CGFloat(ScanAllowanceManager.freeDailyScanLimit), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                
                                HStack {
                                    Label("\(allowance.remainingDailyScans) scans remaining", systemImage: "bolt.fill")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Label("Resets in \(allowance.formattedResetCountdown)", systemImage: "clock.arrow.circlepath")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    } header: {
                        Text("Membership & Allowance")
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    
                    // MARK: - Offline Corrections & AI Learning
                    Section {
                        NavigationLink(destination: CorrectionQueueView()) {
                            HStack {
                                Label {
                                    Text("Correction Queue")
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: "tray.and.arrow.up.fill")
                                        .foregroundColor(.cyan)
                                }
                                
                                Spacer()
                                
                                if feedbackService.pendingCount > 0 {
                                    Text("\(feedbackService.pendingCount) pending")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.amberGold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.amberGold.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Toggle(isOn: $feedbackService.modelImprovementOptIn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contribute to AI Improvement")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Shares anonymized mineral photos and diagnostic labels to refine classification models.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .tint(.emeraldGreen)
                    } header: {
                        Text("AI Continuous Learning")
                    } footer: {
                        Text("No personal identifiers or location coordinates are ever attached to model improvement telemetry.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    
                    // MARK: - Scanning & Hardware Preferences
                    Section("Scanner Preferences") {
                        Toggle(isOn: $autoTorch) {
                            Label("Auto-Torch in Low Light", systemImage: "flashlight.on.fill")
                                .foregroundColor(.white)
                        }
                        .tint(.amberGold)
                        
                        Toggle(isOn: $hapticFeedback) {
                            Label("Haptic Feedback on Scan", systemImage: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.white)
                        }
                        .tint(.amberGold)
                        
                        Toggle(isOn: $highPrecisionCloud) {
                            VStack(alignment: .leading, spacing: 2) {
                                Label("High-Precision Multimodal AI", systemImage: "sparkles")
                                    .foregroundColor(.white)
                                Text("Combines on-device vision with Gemini Vision 2.5 Flash for nuanced crystal classification.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .tint(.cyan)
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    
                    // MARK: - Collection Storage & Backup
                    Section("Data & Storage") {
                        HStack {
                            Label("Vault Specimens", systemImage: "square.stack.3d.up.fill")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(specimens.count) \(storeKit.isProPurchased ? "saved" : "of \(ScanAllowanceManager.freeCollectionLimit)")")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Button(action: exportCollectionData) {
                            Label("Export Collection Metadata (JSON)", systemImage: "square.and.arrow.up")
                                .foregroundColor(.cyan)
                        }
                        
                        Button(action: { showClearCacheAlert = true }) {
                            Label("Clear Local Image Cache", systemImage: "trash")
                                .foregroundColor(.coralRed)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    
                    // MARK: - About & Mineralogy Engine
                    Section("About Gem ID Scanner") {
                        HStack {
                            Text("Mineral Database")
                                .foregroundColor(.white)
                            Spacer()
                            Text("v2026.4 (500+ Species)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Classification Core")
                                .foregroundColor(.white)
                            Spacer()
                            Text("CoreML 1.4 + Gemini 2.5")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("App Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0 (Build 2026.10)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Button("Restore Purchases") {
                            Task { await storeKit.restorePurchases() }
                        }
                        .foregroundColor(.amberGold)
                        
                        Button("Terms of Service") {
                            showTerms = true
                        }
                        .foregroundColor(.white.opacity(0.8))
                        
                        Button("Privacy Policy") {
                            showPrivacy = true
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showTerms) {
                NavigationStack {
                    LegalDocumentView(title: "Terms of Service", content: LegalDocumentContent.terms)
                }
            }
            .sheet(isPresented: $showPrivacy) {
                NavigationStack {
                    LegalDocumentView(title: "Privacy Policy", content: LegalDocumentContent.privacy)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let text = exportedDataString {
                    ShareActivitySheet(activityItems: [text])
                }
            }
            .alert("Clear Local Image Cache?", isPresented: $showClearCacheAlert) {
                Button("Clear Cache", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                    withAnimation {
                        cacheClearedToast = true
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        withAnimation {
                            cacheClearedToast = false
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears temporary download caches and optimizes device storage. Your saved specimen vault will not be affected.")
            }
        }
    }
    
    private func exportCollectionData() {
        let exportableList = specimens.map { item in
            [
                "mineralName": item.mineralName,
                "confidence": "\(Int(item.confidence * 100))%",
                "confidenceBand": item.confidenceBandRaw,
                "dateAdded": ISO8601DateFormatter().string(from: item.dateAdded),
                "form": item.form,
                "notes": item.notes,
                "weightGrams": item.weightGrams ?? 0,
                "originSource": item.originSource ?? ""
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportableList, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.exportedDataString = jsonString
            self.showExportSheet = true
        }
    }
}

private struct LegalDocumentView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(5)
                .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundColor(.amberGold)
            }
        }
    }
}

private enum LegalDocumentContent {
    static let terms = """
    Gem ID Scanner Terms of Service
    
    1. Introduction
    Welcome to Gem ID Scanner. By using our application, you agree to these Terms of Service. Please read them carefully.
    
    2. Educational & Informational Purpose
    Gem ID Scanner provides visual and multimodal AI mineral identification suggestions for educational, recreational, and rockhounding purposes. Specimen identifications should not be relied upon as certified appraisals or legal valuations for commercial jewelry transactions.
    
    3. Subscription Billing & Cancellations
    - Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.
    - Payment is charged to your Apple ID account at confirmation of purchase.
    - You can manage and cancel your subscriptions anytime in your Apple ID Account Settings after purchase.
    
    4. Contact & Support
    For assistance or inquiries, please contact support@gemidscanner.app.
    """
    
    static let privacy = """
    Gem ID Scanner Privacy Policy
    
    1. Privacy First Architecture
    We value your privacy. Gem ID Scanner processes initial visual analyses on-device using CoreML whenever possible.
    
    2. Cloud Vision Processing
    When high-confidence cloud identification is active, specimen images are transmitted securely over TLS to Gemini Vision API for inference. Images are not retained or used for user profiling.
    
    3. Anonymized Improvement Feedback
    If you opt into Model Improvement, submitted mineral corrections and anonymous diagnostic metadata are used solely to retrain and refine our mineralogy classification dataset. No personally identifiable information (PII) is attached.
    
    4. Local SwiftData Storage
    Your saved specimen vault, collection notes, photos, and favorites remain stored locally on your device in your private SwiftData container.
    """
}
