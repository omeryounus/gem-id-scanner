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
    
    @State private var showPaywall = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showClearCacheAlert = false
    @State private var showExportSheet = false
    @State private var exportedDataString: String?
    @State private var exportZipURL: URL?
    @State private var showZipExportSheet = false
    @State private var syncToastMessage: String?
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
                                        Text("Field Bench Pro Active")
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
                    
                    // MARK: - Beta Corrections Queue & Model Training
                    Section {
                        // Live Queue Count & Header Card
                        HStack {
                            Label {
                                Text("Beta Corrections Queue")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            } icon: {
                                Image(systemName: "tray.and.arrow.up.fill")
                                    .foregroundColor(.amberGold)
                            }
                            
                            Spacer()
                            
                            if feedbackService.queuedCorrections.isEmpty {
                                Text("0 items")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            } else {
                                HStack(spacing: 6) {
                                    if feedbackService.pendingCount > 0 {
                                        Text("\(feedbackService.pendingCount) pending")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.amberGold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.amberGold.opacity(0.18))
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text("\(feedbackService.queuedCorrections.count) total")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        Button(action: handleExportDataset) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Export Dataset")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(feedbackService.queuedCorrections.isEmpty ? Color.white.opacity(0.2) : Color.amberGold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(feedbackService.queuedCorrections.isEmpty)
                        .padding(.vertical, 2)
                        
                        // Queue Inspector Navigation Link
                        NavigationLink(destination: CorrectionQueueView()) {
                            HStack {
                                Text("Inspect & Manage Feedback Queue")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        
                        // AI Model Improvement Opt-in Toggle
                        Toggle(isOn: $feedbackService.modelImprovementOptIn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contribute to AI Improvement")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Uploads your corrected mineral name and the scan labels. Specimen photos stay on this iPhone.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .tint(.emeraldGreen)
                    } header: {
                        Text("Beta Corrections & Training Pipeline")
                    } footer: {
                        Text("A local dataset export still includes full-resolution JPEGs. Cloud sync uploads labels only: predictions, your correction, and prompt SHA-256 \(String(AppleVisionService.promptSHA256.prefix(8))).")
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
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                    
                    Section("Hybrid Identification") {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: AppleVisionService.shared.isVisionAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(AppleVisionService.shared.isVisionAvailable ? .emeraldGreen : .amberGold)
                            Text(AppleVisionService.shared.availabilitySummary)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Text("Each scan sends the photo to Gemini through Firebase AI Logic. If Gemini does not answer, the result falls back to the on-device color rank.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
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
                    Section("About Field Bench") {
                        HStack {
                            Text("Mineral Database")
                                .foregroundColor(.white)
                            Spacer()
                            Text("v2026.4 (60 Curated Species)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Classification Core")
                                .foregroundColor(.white)
                            Spacer()
                            Text("Color shortlist + \(AppleVisionService.modelName)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack {
                            Text("App Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0") (Build \((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "3"))")
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
            .sheet(isPresented: $showZipExportSheet) {
                if let url = exportZipURL {
                    ShareActivitySheet(activityItems: [url])
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
            .overlay(alignment: .bottom) {
                if let toast = syncToastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.emeraldGreen)
                        Text(toast)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.emeraldGreen.opacity(0.4), lineWidth: 1))
                    .shadow(radius: 10)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private func handleExportDataset() {
        if let zipURL = feedbackService.exportCorrectionsDatasetZip() {
            self.exportZipURL = zipURL
            self.showZipExportSheet = true
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
