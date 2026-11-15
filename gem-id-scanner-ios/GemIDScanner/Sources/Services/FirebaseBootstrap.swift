import Foundation
import DeviceCheck
import FirebaseCore
import FirebaseAppCheck

/// Starts Firebase before any AI Logic call.
///
/// App Check is required for Firebase AI Logic. Debug builds use the App Check
/// debug provider, which the hackathon accepts. Release builds use App Attest,
/// with DeviceCheck on hardware that cannot attest.
enum FirebaseBootstrap {
    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var isConfigured = false
        var statusMessage = "Firebase has not been configured."
    }

    private static let state = State()

    static var isConfigured: Bool {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.isConfigured
    }

    static var statusMessage: String {
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.statusMessage
    }

    static func configure() {
        state.lock.lock()
        if state.isConfigured {
            state.lock.unlock()
            return
        }
        guard let plist = bundledOptions() else {
            state.statusMessage = "Add GoogleService-Info.plist to GemIDScanner/Resources. See README."
            state.lock.unlock()
            return
        }
        state.lock.unlock()

        #if DEBUG
        installDebugAppCheckToken()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(GemAppCheckProviderFactory())
        #endif

        FirebaseApp.configure(options: plist)
        state.lock.lock()
        state.isConfigured = true
        state.statusMessage = "Firebase AI Logic is configured."
        state.lock.unlock()
    }

    #if DEBUG
    /// Home-screen launches do not receive the Xcode scheme environment.
    /// A debug install can supply the registered token in Info.plist.
    private static func installDebugAppCheckToken() {
        guard getenv("FIRAAppCheckDebugToken") == nil,
              let token = Bundle.main.object(forInfoDictionaryKey: "FirebaseAppCheckDebugToken") as? String,
              !token.isEmpty,
              !token.contains("REPLACE")
        else { return }
        setenv("FIRAAppCheckDebugToken", token, 0)
    }
    #endif

    private static func bundledOptions() -> FirebaseOptions? {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let raw = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else {
            return nil
        }

        let apiKey = (raw["API_KEY"] as? String) ?? ""
        let appID = (raw["GOOGLE_APP_ID"] as? String) ?? ""
        let sender = (raw["GCM_SENDER_ID"] as? String) ?? ""
        let project = (raw["PROJECT_ID"] as? String) ?? ""
        guard !apiKey.isEmpty, !apiKey.contains("REPLACE"),
              !appID.isEmpty, !appID.contains("REPLACE"),
              !sender.isEmpty, !sender.contains("REPLACE"),
              !project.isEmpty, !project.contains("REPLACE")
        else {
            return nil
        }

        let options = FirebaseOptions(googleAppID: appID, gcmSenderID: sender)
        options.apiKey = apiKey
        options.projectID = project
        options.bundleID = (raw["BUNDLE_ID"] as? String) ?? "com.gemidscanner.app"
        if let bucket = raw["STORAGE_BUCKET"] as? String, !bucket.isEmpty {
            options.storageBucket = bucket
        }
        if let clientID = raw["CLIENT_ID"] as? String, !clientID.isEmpty {
            options.clientID = clientID
        }
        return options
    }
}

/// Production App Check provider. Debug builds do not use this factory.
final class GemAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        if DCAppAttestService.shared.isSupported, let provider = AppAttestProvider(app: app) {
            return provider
        }
        return DeviceCheckProvider(app: app)
    }
}
