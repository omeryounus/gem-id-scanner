import Foundation
import UIKit
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Stage 2 identification through Firebase AI Logic hybrid inference.
///
/// A capable device ranks an on-device color brief with Apple's Foundation
/// Model. That rank is only a fallback. Gemini sees the photo through Firebase
/// AI Logic on every scan.
public final class AppleVisionService: @unchecked Sendable {
    public static let shared = AppleVisionService()
    public static let modelName = "Firebase AI Logic"

    public static let onDevicePromptTemplate: String = """
    You are an expert gemologist. You cannot see a photograph. Rank the specimen using only the on-device measurements in the user message.
    Stage 1 color shortlist (hint only): "{STAGE_1_HINT}".

    You MUST choose primaryName, secondName, and thirdName from this catalog only:
    {CATALOG_NAMES}

    Catalog notes and lookalike tests:
    {CATALOG_NOTES}

    Rules:
    - Never invent a species that is not in the catalog.
    - Do not claim crystal habit, luster, fracture, or zoning. You were not shown the photo.
    - Say that the rank is from measured color and the catalog shortlist.
    - Confidence must never exceed 0.70. A color brief cannot prove the species.
    - If lookalikes are close, lower confidence and name the twins in secondName and thirdName.
    """

    public static let cloudPromptTemplate: String = """
    You are an expert gemologist. Identify the mineral, gemstone, or rock in the attached photograph.
    Stage 1 on-device color shortlist (hint only, not a classification): "{STAGE_1_HINT}".

    You MUST choose primaryName, secondName, and thirdName from this catalog only:
    {CATALOG_NAMES}

    Catalog notes and lookalike tests:
    {CATALOG_NOTES}

    Rules:
    - Never invent a species that is not in the catalog.
    - Never default to Clear Quartz, Glass, Slag, or Calcite when a more specific catalog match fits the photo.
    - Confidence must never exceed 0.96. Optical photos cannot prove chemistry.
    - If lookalikes are close, lower confidence and name the twins in secondName and thirdName.
    - Describe only visual cues you can actually see (habit, luster, fracture, color zoning, form).
    - Reply with one JSON object and no markdown. Keys: primaryName, primaryConfidence, secondName, secondConfidence, thirdName, thirdConfidence, family, identifiedForm, visualCues, lookalikeTwin, reasoning, separatingTests. separatingTests is an array of objects with testName and diagnosticRule. visualCues is an array of strings.
    """

    public static var promptTemplate: String { onDevicePromptTemplate + "\n" + cloudPromptTemplate }

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

    public var isHybridReady: Bool { FirebaseBootstrap.isConfigured }

    public var isVisionAvailable: Bool { isHybridReady }

    public var availabilitySummary: String {
        guard FirebaseBootstrap.isConfigured else {
            return FirebaseBootstrap.statusMessage
        }
        #if canImport(FoundationModels)
        if #available(iOS 26.4, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "The photo is sent to Gemini through Firebase AI Logic. Apple Intelligence ranks the color on this iPhone if Gemini does not answer."
            case .unavailable(.deviceNotEligible):
                return "This iPhone cannot run the on-device model. Scans use Gemini through Firebase AI Logic."
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence is off, so scans use Gemini through Firebase AI Logic."
            case .unavailable(.modelNotReady):
                return "Apple Intelligence is still downloading. Until it is ready, scans use Gemini."
            case .unavailable:
                return "The on-device model is unavailable. Scans use Gemini through Firebase AI Logic."
            }
        }
        #endif
        return "Hybrid identification is ready through Firebase AI Logic."
    }

    /// Ranks a specimen with Firebase AI Logic. The photo is sent to Gemini.
    public func analyzeSecondOpinion(image: UIImage, stage1: Stage1Inference) async throws -> Stage2Inference {
        guard FirebaseBootstrap.isConfigured else {
            return unavailableShortlist(
                stage1: stage1,
                explanation: FirebaseBootstrap.statusMessage
            )
        }

        let settings = await HybridRuntimeConfig.load()
        let measurements = measuredColorSummary(image)
        let onDeviceInstructions = filledTemplate(Self.onDevicePromptTemplate, stage1: stage1)
        let onDevicePrompt = """
        On-device measurements only. No photograph is attached.
        Measured color: \(measurements).
        Rank the catalog from these measurements.
        """

        var onDeviceAnswer: Stage2Inference?
        if #available(iOS 26.4, *) {
            do {
                let ranked = try await HybridIdentificationService.rankFromMeasurements(
                    modelName: settings.geminiModelName,
                    instructions: onDeviceInstructions,
                    userPrompt: onDevicePrompt
                )
                let route = HybridIdentificationService.ranOnDevice(ranked.modelVersion) ? "on_device" : "cloud_text"
                let mapped = mapDraft(
                    ranked.draft.ranked(),
                    stage1: stage1,
                    route: route,
                    modelVersion: ranked.modelVersion,
                    photoLeftDevice: false
                )
                onDeviceAnswer = mapped
            } catch {
                onDeviceAnswer = nil
            }
        }

        do {
            let cloudInstructions = filledTemplate(Self.cloudPromptTemplate, stage1: stage1)
            let cloudPrompt = """
            Identify the specimen in the attached photograph.
            On-device color measurement: \(measurements).
            Return the JSON object described in your instructions.
            """
            let cloud = try await HybridIdentificationService.rankFromPhoto(
                modelName: settings.geminiModelName,
                instructions: cloudInstructions,
                userPrompt: cloudPrompt,
                image: image
            )
            if let parsed = RankedIdentification.parse(cloud.text) {
                return mapDraft(
                    parsed,
                    stage1: stage1,
                    route: "cloud_vision",
                    modelVersion: cloud.modelVersion,
                    photoLeftDevice: true
                )
            }
        } catch {
            if let onDeviceAnswer {
                return onDeviceAnswer
            }
            return unavailableShortlist(
                stage1: stage1,
                explanation: "Firebase AI Logic could not finish this scan. \(error.localizedDescription)"
            )
        }

        if let onDeviceAnswer {
            return onDeviceAnswer
        }
        return unavailableShortlist(
            stage1: stage1,
            explanation: "Gemini did not return a catalog identification."
        )
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
                "Firebase AI Logic did not return a catalog rank",
                "Use hardness, streak, and lookalike tests to confirm"
            ],
            suggestedTests: mineral?.ruleOutTests.prefix(2).map { String($0) } ?? ["Mohs Hardness Scratch Test", "Ceramic Streak Tile Test"],
            lookalikeDisambiguation: primaryLookalike.map { "Distinguish from \($0.mineralName): \($0.separatingTest)" },
            candidate2Name: primaryLookalike?.mineralName,
            candidate2Score: 0.15,
            candidate3Name: secondaryLookalike?.mineralName,
            candidate3Score: 0.10,
            family: mineral?.family,
            identifiedForm: "rough",
            inferenceRoute: "shortlist",
            modelVersion: "",
            photoLeftDevice: false
        )
    }

    private func filledTemplate(_ template: String, stage1: Stage1Inference) -> String {
        let catalogNames = MineralDatabase.shared.allMinerals.map(\.name).sorted().joined(separator: ", ")
        return template
            .replacingOccurrences(of: "{STAGE_1_HINT}", with: stage1Hint(stage1))
            .replacingOccurrences(of: "{CATALOG_NAMES}", with: catalogNames)
            .replacingOccurrences(of: "{CATALOG_NOTES}", with: catalogNotes(stage1: stage1))
    }

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

    private func mapDraft(
        _ draft: RankedIdentification,
        stage1: Stage1Inference,
        route: String,
        modelVersion: String,
        photoLeftDevice: Bool
    ) -> Stage2Inference {
        let primary = resolveCatalogName(draft.primaryName) ?? MineralDatabase.shared.find(byName: stage1.topMineralName)?.name ?? stage1.topMineralName
        let second = resolveCatalogName(draft.secondName)
        let third = resolveCatalogName(draft.thirdName)
        let cap = route == "on_device" ? 0.70 : 0.96

        let tests = draft.separatingTests.compactMap { test -> String? in
            let name = test.testName.trimmingCharacters(in: .whitespacesAndNewlines)
            let rule = test.diagnosticRule.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return rule.isEmpty ? name : "\(name): \(rule)"
        }

        let defaultReason: String
        switch route {
        case "on_device":
            defaultReason = "On-device Apple Intelligence ranked the measured color against the catalog. The photo stayed on this iPhone."
        case "cloud_vision":
            defaultReason = "Gemini examined the photograph through Firebase AI Logic."
        default:
            defaultReason = "Firebase AI Logic ranked the catalog from the on-device color brief."
        }

        return Stage2Inference(
            topMineralName: primary,
            score: min(clampScore(draft.primaryConfidence), cap),
            reasoning: draft.reasoning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultReason : draft.reasoning,
            visualCuesObserved: draft.visualCues.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            suggestedTests: tests,
            lookalikeDisambiguation: draft.lookalikeTwin.isEmpty ? second.map { "Distinguish from \($0)" } : draft.lookalikeTwin,
            candidate2Name: second,
            candidate2Score: draft.secondConfidence > 0 ? min(clampScore(draft.secondConfidence), cap) : nil,
            candidate3Name: third,
            candidate3Score: draft.thirdConfidence > 0 ? min(clampScore(draft.thirdConfidence), cap) : nil,
            family: draft.family.isEmpty ? MineralDatabase.shared.find(byName: primary)?.family : draft.family,
            identifiedForm: draft.identifiedForm.isEmpty ? "rough" : draft.identifiedForm,
            inferenceRoute: route,
            modelVersion: modelVersion,
            photoLeftDevice: photoLeftDevice
        )
    }

    private func resolveCatalogName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return MineralDatabase.shared.find(byName: trimmed)?.name
    }

    private func clampScore(_ score: Double) -> Double {
        min(max(score, 0.05), 0.96)
    }

    private func measuredColorSummary(_ image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "unmeasured" }
        let side = 16
        let cropSide = min(cgImage.width, cgImage.height)
        let originX = (cgImage.width - cropSide) / 2
        let originY = (cgImage.height - cropSide) / 2
        let cropped = cgImage.cropping(to: CGRect(x: originX, y: originY, width: cropSide, height: cropSide)) ?? cgImage
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return "unmeasured"
        }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return "unmeasured" }
        let pixels = data.bindMemory(to: UInt8.self, capacity: side * side * 4)
        var sumR = 0.0, sumG = 0.0, sumB = 0.0
        var sumSq = 0.0
        let count = side * side
        for index in 0..<count {
            let offset = index * 4
            let r = Double(pixels[offset]) / 255.0
            let g = Double(pixels[offset + 1]) / 255.0
            let b = Double(pixels[offset + 2]) / 255.0
            sumR += r
            sumG += g
            sumB += b
            let brightness = (r + g + b) / 3.0
            sumSq += brightness * brightness
        }
        let r = sumR / Double(count)
        let g = sumG / Double(count)
        let b = sumB / Double(count)
        let mean = (r + g + b) / 3.0
        let variance = max(0, sumSq / Double(count) - mean * mean)
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        let saturation = maxC == 0 ? 0 : delta / maxC
        var hue = 0.0
        if delta > 0.001 {
            if maxC == r {
                hue = (g - b) / delta
            } else if maxC == g {
                hue = 2 + (b - r) / delta
            } else {
                hue = 4 + (r - g) / delta
            }
            hue *= 60
            if hue < 0 { hue += 360 }
        }
        let hueName: String
        switch hue {
        case 0..<20, 345...360: hueName = "red"
        case 20..<45: hueName = "orange"
        case 45..<70: hueName = "yellow"
        case 70..<160: hueName = "green"
        case 160..<200: hueName = "cyan"
        case 200..<255: hueName = "blue"
        case 255..<290: hueName = "violet"
        default: hueName = "magenta"
        }
        let satWord = saturation < 0.12 ? "pale or gray" : (saturation < 0.4 ? "muted" : "vivid")
        let tone = mean < 0.25 ? "dark" : (mean > 0.75 ? "light" : "mid-tone")
        let pattern = variance > 0.02 ? "mottled" : "fairly even"
        return "\(tone) \(satWord) \(hueName), \(pattern) color across the center"
    }
}

struct ParsedSeparatingTest: Sendable {
    var testName: String
    var diagnosticRule: String
}

struct RankedIdentification: Sendable {
    var primaryName: String
    var primaryConfidence: Double
    var secondName: String
    var secondConfidence: Double
    var thirdName: String
    var thirdConfidence: Double
    var family: String
    var identifiedForm: String
    var visualCues: [String]
    var lookalikeTwin: String
    var reasoning: String
    var separatingTests: [ParsedSeparatingTest]

    static func parse(_ text: String) -> RankedIdentification? {
        var raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}"), start < end {
            raw = String(raw[start...end])
        }
        guard let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        func string(_ key: String) -> String {
            object[key] as? String ?? ""
        }
        func number(_ key: String) -> Double {
            if let value = object[key] as? Double { return value }
            if let value = object[key] as? Int { return Double(value) }
            if let value = object[key] as? String { return Double(value) ?? 0 }
            return 0
        }
        let cues = object["visualCues"] as? [String] ?? []
        let tests = (object["separatingTests"] as? [[String: Any]] ?? []).map {
            ParsedSeparatingTest(
                testName: $0["testName"] as? String ?? "",
                diagnosticRule: $0["diagnosticRule"] as? String ?? ""
            )
        }
        return RankedIdentification(
            primaryName: string("primaryName"),
            primaryConfidence: number("primaryConfidence"),
            secondName: string("secondName"),
            secondConfidence: number("secondConfidence"),
            thirdName: string("thirdName"),
            thirdConfidence: number("thirdConfidence"),
            family: string("family"),
            identifiedForm: string("identifiedForm"),
            visualCues: cues,
            lookalikeTwin: string("lookalikeTwin"),
            reasoning: string("reasoning"),
            separatingTests: tests
        )
    }
}

#if canImport(FoundationModels)
@available(iOS 26.4, *)
@Generable
struct MineralIdentificationDraft {
    @Guide(description: "Primary mineral name. Must match a catalog name exactly.")
    var primaryName: String

    @Guide(description: "Confidence from 0.05 to 0.70. Never exceed 0.70.")
    var primaryConfidence: Double

    @Guide(description: "Second-best catalog mineral name.")
    var secondName: String

    @Guide(description: "Second-best confidence from 0.01 to 0.70.")
    var secondConfidence: Double

    @Guide(description: "Third-best catalog mineral name.")
    var thirdName: String

    @Guide(description: "Third-best confidence from 0.01 to 0.70.")
    var thirdConfidence: Double

    @Guide(description: "Mineral family if known, otherwise an empty string.")
    var family: String

    @Guide(description: "Specimen form: rough, tumbled, cabochon, cut, cluster, or slab.")
    var identifiedForm: String

    @Guide(description: "Only the measurements you were given. Do not invent visual cues.")
    var visualCues: [String]

    @Guide(description: "Closest lookalike twin from the catalog.")
    var lookalikeTwin: String

    @Guide(description: "Short reason based only on the color measurements and catalog.")
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

@available(iOS 26.4, *)
extension MineralIdentificationDraft {
    func ranked() -> RankedIdentification {
        RankedIdentification(
            primaryName: primaryName,
            primaryConfidence: primaryConfidence,
            secondName: secondName,
            secondConfidence: secondConfidence,
            thirdName: thirdName,
            thirdConfidence: thirdConfidence,
            family: family,
            identifiedForm: identifiedForm,
            visualCues: visualCues,
            lookalikeTwin: lookalikeTwin,
            reasoning: reasoning,
            separatingTests: separatingTests.map {
                ParsedSeparatingTest(testName: $0.testName, diagnosticRule: $0.diagnosticRule)
            }
        )
    }
}
#endif
