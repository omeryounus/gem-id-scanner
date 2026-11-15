import Foundation
import FirebaseCore
import FirebaseAppCheck

/// Starts Firebase before any AI Logic call.
///
/// App Check is required for Firebase AI Logic. Debug builds use the App Check
/// debug provider, which the hackathon accepts. Release builds use App Attest,
/// with DeviceCheck on hardware that cannot attest.
enum FirebaseBootstrap {
    private(set) static var isConfigured = false
    private(set) static var statusMessage = "Firebase has not been configured."

    static func configure() {
        guard !isConfigured else { return }
        guard let plist = bundledOptions() else {
            statusMessage = "Add GoogleService-Info.plist to GemIDScanner/Resources. See README."
            return
        }

        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(GemAppCheckProviderFactory())
        #endif

        FirebaseApp.configure(options: plist)
        isConfigured = true
        statusMessage = "Firebase AI Logic is configured."
    }

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
        if #available(iOS 14.0, *), AppAttestProvider.isSupported {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
    }
}
