import SwiftUI

/// Main Root Tab Navigation for Gem ID Scanner.
///
/// Houses the 3 core application destinations:
/// 1. Scanner (CameraHomeView)
/// 2. Vault / Collection (CollectionView)
/// 3. Settings & Diagnostics (SettingsView)
public struct MainTabView: View {
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    @EnvironmentObject private var allowance: ScanAllowanceManager
    @EnvironmentObject private var storeKit: StoreKitService
    
    @State private var selectedTab: TabDestination = .scanner
    
    public enum TabDestination: Int, Hashable {
        case scanner = 0
        case collection = 1
        case settings = 2
    }
    
    public init() {
        configureTabBarAppearance()
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Mineral Camera Scanner
            CameraHomeView()
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }
                .tag(TabDestination.scanner)
            
            // Tab 2: Specimen Collection Grid
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
                .tag(TabDestination.collection)
            
            // Tab 3: Settings & Preferences
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .badge(feedbackService.pendingCount > 0 ? "\(feedbackService.pendingCount)" : nil)
                .tag(TabDestination.settings)
        }
        .tint(.amberGold)
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 0.98)
        
        // Item unselected state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 1.0, alpha: 0.45)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 1.0, alpha: 0.45),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Item selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.95, green: 0.68, blue: 0.18, alpha: 1.0)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.95, green: 0.68, blue: 0.18, alpha: 1.0),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
