import Foundation
import UIKit
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Stage 2 on-device vision analysis using Apple Foundation Models.
///
/// Photos stay on device. The model must choose from the 60-species catalog
/// and is given Stage 1 only as a hint, plus lookalike / rule-out tests.
public final class AppleVisionService: @unchecked Sendable {
    public static let shared = AppleVisionService()
    public static let modelName = "Apple Intelligence"

    public static let promptTemplate: String = """
    You are an expert gemologist. Identify the mineral, gemstone, or rock in the photograph.
    Stage 1 on-device color shortlist (hint only, not a classification): "{STAGE_1_HINT}".

    You MUST choose pred_1, pred_2, and pred_3 from this catalog only:
    {CATALOG_NAMES}

    Catalog notes and lookalike tests:
    {CATALOG_NOTES}

    Rules:
    - Never invent a species that is not in the catalog.
    - Never default to Clear Quartz, Glass, Slag, or Calcite when a more specific catalog match fits the photo.
    - Confidence must never exceed 0.96. Optical photos cannot prove chemistry.
    - If lookalikes are close, lower confidence and name the twins in pred_2 / pred_3.
    - Describe only visual cues you can actually see (habit, luster, fracture, color zoning, form).
    """

    public static var promptSHA256: String {
        let inputData = Data(promptTemplate.utf8)
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: inputData)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        var hash: UInt64 = 5381
        for byte in inputData {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "%016llx", hash)
        #endif
    }

    public init() {}

    public var isVisionAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.4, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    public var availabilitySummary: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.4, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "On-device Apple Intelligence is ready. Photos stay on this device."
            case .unavailable(.deviceNotEligible):
                return "This device does not support Apple Intelligence. Scans use the catalog color shortlist only."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Turn on Apple Intelligence in Settings to identify stones on-device."
            case .unavailable(.modelNotReady):
                return "Apple Intelligence is still downloading. Try again in a few minutes."
            case .unavailable:
                return "On-device vision is unavailable. Scans use the catalog color shortlist only."
            }
        }
        #endif
        return "On-device vision requires iOS 26.4 and Apple Intelligence."
    }

    /// Analyzes a specimen photo with the on-device Foundation Model.
    public func analyzeSecondOpinion(image: UIImage, stage1: Stage1Inference) async throws -> Stage2Inference {
        #if canImport(FoundationModels)
        if #available(iOS 26.4, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return try await performOnDeviceRequest(image: image, stage1: stage1)
            case .unavailable(.appleIntelligenceNotEnabled):
                return unavailableShortlist(stage1: stage1, explanation: "Apple Intelligence is turned off.")
            case .unavailable(.modelNotReady):
                return unavailableShortlist(stage1: stage1, explanation: "Apple Intelligence is not ready yet.")
            case .unavailable(.deviceNotEligible):
                return unavailableShortlist(stage1: stage1, explanation: "This device does not support Apple Intelligence.")
            case .unavailable:
                return unavailableShortlist(stage1: stage1, explanation: "On-device Apple Intelligence is unavailable.")
            }
        }
        #endif
        return unavailableShortlist(stage1: stage1, explanation: "On-device vision requires iOS 26.4.")
    }

    public func unavailableShortlist(stage1: Stage1Inference, explanation: String) -> Stage2Inference {
        let mineral = MineralDatabase.shared.find(byName: stage1.topMineralName)
        let name = mineral?.name ?? stage1.topMineralName
        let lookalikes = mineral?.topLookalikes ?? []
        let primaryLookalike = lookalikes.first
        let secondaryLookalike = lookalikes.dropFirst().first

        return Stage2Inference(
            topMineralName: name,
            score: min(stage1.score, 0.35),
            reasoning: "\(explanation) \(name) is only an on-device color shortlist. Confirm with physical tests.",
            visualCuesObserved: [
                "Central image color compared with the catalog color range",
                "On-device vision model did not analyze this photo",
                "Use hardness, streak, and lookalike tests to confirm"
            ],
            suggestedTests: mineral?.ruleOutTests.prefix(2).map { String($0) } ?? ["Mohs Hardness Scratch Test", "Ceramic Streak Tile Test"],
            lookalikeDisambiguation: primaryLookalike.map { "Distinguish from \($0.mineralName): \($0.separatingTest)" },
            candidate2Name: primaryLookalike?.mineralName,
            candidate2Score: 0.15,
            candidate3Name: secondaryLookalike?.mineralName,
            candidate3Score: 0.10,
            family: mineral?.family,
            identifiedForm: "rough"
        )
    }

    #if canImport(FoundationModels)
    @available(iOS 26.4, *)
    private func performOnDeviceRequest(image: UIImage, stage1: Stage1Inference) async throws -> Stage2Inference {
        guard let cgImage = image.cgImage else {
            throw NSError(
                domain: "AppleVisionService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid image data for on-device vision."]
            )
        }

        let catalog = MineralDatabase.shared.allMinerals
        let catalogNames = catalog.map(\.name).sorted().joined(separator: ", ")
        let shortlistNotes = catalogNotes(stage1: stage1)
        let instructions = Self.promptTemplate
            .replacingOccurrences(of: "{STAGE_1_HINT}", with: stage1Hint(stage1))
            .replacingOccurrences(of: "{CATALOG_NAMES}", with: catalogNames)
            .replacingOccurrences(of: "{CATALOG_NOTES}", with: shortlistNotes)

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(
            generating: MineralIdentificationDraft.self,
            options: GenerationOptions(samplingMode: .greedy)
        ) {
            "Identify the specimen in this photograph. Choose only catalog names."
            Attachment(cgImage)
        }

        return mapDraft(response.content, stage1: stage1)
    }
    #endif

    private func stage1Hint(_ stage1: Stage1Inference) -> String {
        let ranked = stage1.allProbabilities.sorted { $0.value > $1.value }.prefix(5)
        if ranked.isEmpty {
            return stage1.topMineralName
        }
        return ranked.map { "\($0.key) (\(Int($0.value * 100))%)" }.joined(separator: ", ")
    }

    private func catalogNotes(stage1: Stage1Inference) -> String {
        var names = [stage1.topMineralName]
        names.append(contentsOf: stage1.allProbabilities.keys.sorted())
        var seen = Set<String>()
        var notes: [String] = []

        for name in names {
            guard let mineral = MineralDatabase.shared.find(byName: name),
                  seen.insert(mineral.name).inserted else { continue }
            let lookalikes = mineral.topLookalikes.prefix(2).map {
                "\($0.mineralName) (\($0.separatingTest))"
            }.joined(separator: "; ")
            let tests = mineral.ruleOutTests.prefix(2).joined(separator: "; ")
            notes.append("\(mineral.name): lookalikes \(lookalikes.isEmpty ? "none listed" : lookalikes). Tests: \(tests.isEmpty ? "Mohs and streak" : tests).")
            if notes.count >= 8 { break }
        }

        return notes.joined(separator: "\n")
    }

    #if canImport(FoundationModels)
    @available(iOS 26.4, *)
    private func mapDraft(_ draft: MineralIdentificationDraft, stage1: Stage1Inference) -> Stage2Inference {
        let primary = resolveCatalogName(draft.primaryName) ?? MineralDatabase.shared.find(byName: stage1.topMineralName)?.name ?? stage1.topMineralName
        let second = resolveCatalogName(draft.secondName)
        let third = resolveCatalogName(draft.thirdName)

        let tests = draft.separatingTests.compactMap { test -> String? in
            let name = test.testName.trimmingCharacters(in: .whitespacesAndNewlines)
            let rule = test.diagnosticRule.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return rule.isEmpty ? name : "\(name): \(rule)"
        }

        return Stage2Inference(
            topMineralName: primary,
            score: clampScore(draft.primaryConfidence),
            reasoning: draft.reasoning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "On-device Apple Intelligence compared visible habit, luster, and color with the catalog."
                : draft.reasoning,
            visualCuesObserved: draft.visualCues.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            suggestedTests: tests,
            lookalikeDisambiguation: draft.lookalikeTwin.isEmpty ? second.map { "Distinguish from \($0)" } : draft.lookalikeTwin,
            candidate2Name: second,
            candidate2Score: draft.secondConfidence > 0 ? clampScore(draft.secondConfidence) : nil,
            candidate3Name: third,
            candidate3Score: draft.thirdConfidence > 0 ? clampScore(draft.thirdConfidence) : nil,
            family: draft.family.isEmpty ? MineralDatabase.shared.find(byName: primary)?.family : draft.family,
            identifiedForm: draft.identifiedForm.isEmpty ? "rough" : draft.identifiedForm
        )
    }
    #endif

    private func resolveCatalogName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return MineralDatabase.shared.find(byName: trimmed)?.name
    }

    private func clampScore(_ score: Double) -> Double {
        min(max(score, 0.05), 0.96)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.4, *)
@Generable
struct MineralIdentificationDraft {
    @Guide(description: "Primary mineral name. Must match a catalog name exactly.")
    var primaryName: String

    @Guide(description: "Confidence from 0.05 to 0.96. Never exceed 0.96.")
    var primaryConfidence: Double

    @Guide(description: "Second-best catalog mineral name.")
    var secondName: String

    @Guide(description: "Second-best confidence from 0.01 to 0.96.")
    var secondConfidence: Double

    @Guide(description: "Third-best catalog mineral name.")
    var thirdName: String

    @Guide(description: "Third-best confidence from 0.01 to 0.96.")
    var thirdConfidence: Double

    @Guide(description: "Mineral family if known.")
    var family: String

    @Guide(description: "Specimen form: rough, tumbled, cabochon, cut, cluster, or slab.")
    var identifiedForm: String

    @Guide(description: "Visible optical cues only.")
    var visualCues: [String]

    @Guide(description: "Closest lookalike twin from the catalog.")
    var lookalikeTwin: String

    @Guide(description: "Short geological reasoning based on the photo.")
    var reasoning: String

    @Guide(description: "Physical tests that separate the top candidate from lookalikes.")
    var separatingTests: [SeparatingTestDraft]
}

@available(iOS 26.4, *)
@Generable
struct SeparatingTestDraft {
    @Guide(description: "Test name, such as Mohs hardness or streak.")
    var testName: String

    @Guide(description: "What outcome supports or rules out the top candidate.")
    var diagnosticRule: String
}
#endif
