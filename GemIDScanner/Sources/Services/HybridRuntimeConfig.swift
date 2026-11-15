import Foundation
import FirebaseRemoteConfig

/// Remote Config knobs for hybrid identification.
///
/// Defaults keep the app usable before the first fetch. Change
/// `gemini_model_name` in the Firebase console without shipping a new build.
struct HybridRuntimeSettings: Sendable {
    var geminiModelName: String
    var escalationThreshold: Double

    static let fallback = HybridRuntimeSettings(
        geminiModelName: "gemini-3.5-flash-lite",
        escalationThreshold: 0.55
    )
}

enum HybridRuntimeConfig {
    private final class Gate: @unchecked Sendable {
        let lock = NSLock()
        var didPrepare = false
    }

    private static let modelKey = "gemini_model_name"
    private static let thresholdKey = "cloud_escalation_threshold"
    private static let gate = Gate()

    static func load() async -> HybridRuntimeSettings {
        guard FirebaseBootstrap.isConfigured else { return .fallback }
        let remoteConfig = RemoteConfig.remoteConfig()
        gate.lock.lock()
        let needsPrepare = !gate.didPrepare
        if needsPrepare {
            gate.didPrepare = true
        }
        gate.lock.unlock()
        if needsPrepare {
            let settings = RemoteConfigSettings()
            #if DEBUG
            settings.minimumFetchInterval = 0
            #else
            settings.minimumFetchInterval = 43_200
            #endif
            remoteConfig.configSettings = settings
            remoteConfig.setDefaults([
                modelKey: HybridRuntimeSettings.fallback.geminiModelName as NSString,
                thresholdKey: HybridRuntimeSettings.fallback.escalationThreshold as NSNumber
            ])
        }

        _ = try? await remoteConfig.fetchAndActivate()

        let name = remoteConfig.configValue(forKey: modelKey).stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let threshold = remoteConfig.configValue(forKey: thresholdKey).numberValue.doubleValue
        return HybridRuntimeSettings(
            geminiModelName: name.isEmpty ? HybridRuntimeSettings.fallback.geminiModelName : name,
            escalationThreshold: threshold > 0 ? min(threshold, 0.96) : HybridRuntimeSettings.fallback.escalationThreshold
        )
    }
}
