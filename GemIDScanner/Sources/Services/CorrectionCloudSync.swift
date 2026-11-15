import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Opt-in correction sync. Labels go to Firestore. Specimen photos stay on device.
enum CorrectionCloudSync {
    static func upload(items: [MineralCorrectionItem]) async throws -> Set<UUID> {
        guard FirebaseBootstrap.isConfigured else {
            throw NSError(
                domain: "CorrectionCloudSync",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured."]
            )
        }
        if Auth.auth().currentUser == nil {
            _ = try await Auth.auth().signInAnonymously()
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "CorrectionCloudSync",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Anonymous sign-in did not return a user."]
            )
        }

        let database = Firestore.firestore()
        let formatter = ISO8601DateFormatter()
        var uploaded = Set<UUID>()
        for item in items {
            let payload: [String: Any] = [
                "uid": uid,
                "timestamp": formatter.string(from: item.timestamp),
                "pred_1": item.pred_1,
                "conf_1": item.conf_1,
                "pred_2": item.pred_2 ?? "",
                "conf_2": item.conf_2 ?? 0,
                "pred_3": item.pred_3 ?? "",
                "conf_3": item.conf_3 ?? 0,
                "promptSHA256": item.promptSHA256,
                "userCorrectedMineral": item.userCorrectedMineral,
                "form": item.form,
                "verificationBasis": item.verificationBasis,
                "userNotes": item.userNotes
            ]
            try await database.collection("corrections").document(item.id.uuidString).setData(payload)
            uploaded.insert(item.id)
        }
        return uploaded
    }
}
