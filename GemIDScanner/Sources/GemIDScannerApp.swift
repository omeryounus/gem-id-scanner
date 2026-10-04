import SwiftUI
import SwiftData

/// Application Entry Point for Gem ID Scanner.
///
/// Configures:
/// - SwiftData persistent container for `SpecimenRecord` collection models.
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
        do {
            let schema = Schema([SpecimenRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer for SpecimenRecord: \(error)")
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
