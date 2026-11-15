import Foundation
import UIKit
import FirebaseAILogic
import FirebaseCore

/// Stage 2 identification through Firebase AI Logic.
///
/// On-device hybrid inference only accepts text, so a capable iPhone ranks the
/// measured color brief with Apple's Foundation Model and the photo stays on
/// the device. Image prompts, and devices that cannot run the on-device model,
/// use cloud Gemini through the same Firebase AI Logic client.
enum HybridIdentificationService {
    @available(iOS 26.4, *)
    struct OnDeviceRank: Sendable {
        var draft: MineralIdentificationDraft
        var modelVersion: String
    }

    struct CloudRank: Sendable {
        var text: String
        var modelVersion: String
    }

    /// Prefer the on-device model. The SDK falls back to cloud text if it cannot.
    @available(iOS 26.4, *)
    static func rankFromMeasurements(
        modelName: String,
        instructions: String,
        userPrompt: String
    ) async throws -> OnDeviceRank {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let systemModel = FirebaseAI.SystemLanguageModel.default
        let cloudModel = ai.geminiModel(name: modelName)
        let session = ai.generativeModelSession(
            model: .hybridModel(primary: systemModel, secondary: cloudModel),
            instructions: instructions
        )
        let response = try await session.respond(
            to: userPrompt,
            generating: MineralIdentificationDraft.self
        )
        return OnDeviceRank(
            draft: response.content,
            modelVersion: response.rawResponse.modelVersion
        )
    }

    /// Cloud Gemini sees the specimen photo. Used when the on-device model is
    /// missing or its text-only rank is too uncertain to trust.
    static func rankFromPhoto(
        modelName: String,
        instructions: String,
        userPrompt: String,
        image: UIImage
    ) async throws -> CloudRank {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(
                temperature: 0.2,
                responseMIMEType: "application/json"
            ),
            systemInstruction: ModelContent(role: "system", parts: instructions)
        )
        let response = try await model.generateContent(userPrompt, image)
        guard let text = response.text, !text.isEmpty else {
            throw NSError(
                domain: "HybridIdentificationService",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "Gemini returned an empty identification."]
            )
        }
        return CloudRank(text: text, modelVersion: response.modelVersion)
    }

    static func ranOnDevice(_ modelVersion: String) -> Bool {
        let version = modelVersion.lowercased()
        return version.contains("apple-foundation-models") || version.contains("system-language-model")
    }
}
