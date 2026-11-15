import SwiftUI
import SwiftData

/// Application Entry Point for Gem ID Scanner.
///
/// Configures:
/// - SwiftData persistent container for `SpecimenRecord` collection models.
/// - Firebase AI Logic, App Check, and Remote Config before any scan.
/// - Global singleton services for StoreKit 2 subscriptions, daily scan limits,
///   two-stage identification coordinator, and offline correction feedback.
/// - Dark gemological theme and scene phase refresh triggers.
@main
public struct GemIDScannerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var storeKitService = StoreKitService.shared
    @StateObject private var scanAllowanceManager = ScanAllowanceManager.shared
    @StateObject private var correctionService = CorrectionFeedbackService.shared
    @StateObject private var identificationCoordinator = IdentificationCoordinator.shared
    
    let modelContainer: ModelContainer
    
    public init() {
        FirebaseBootstrap.configure()
        ScanAllowanceManager.shared.resetAllowances()
        let schema = Schema([SpecimenRecord.self])
        do {
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to initialize persistent ModelContainer: \(error). Falling back to in-memory container.")
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                self.modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Critical: Failed to initialize in-memory fallback ModelContainer: \(error)")
            }
        }
    }
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(storeKitService)
                .environmentObject(scanAllowanceManager)
                .environmentObject(correctionService)
                .environmentObject(identificationCoordinator)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                scanAllowanceManager.refreshDailyAllowance()
            }
        }
    }
}
