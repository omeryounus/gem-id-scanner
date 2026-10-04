import Foundation
import UIKit
import Security

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Stage 2 multimodal cloud vision analysis service.
///
/// Sends high-resolution specimen imagery to Gemini Vision API for deep geological reasoning,
/// luster/cleavage/crystal habit disambiguation, lookalike separation, and confidence re-ranking.
/// Features resilient timeout management, offline fallback, and custom API key configuration.
public final class GeminiVisionService: @unchecked Sendable {
    public static let shared = GeminiVisionService()
    public static let modelName = "gemini-2.5-flash"
    
    public static let promptTemplate: String = """
    You are an expert gemologist, mineralogist, and crystallographer. Your task is to perform rigorous, non-destructive optical identification of the mineral, gemstone, or rock specimen shown in the provided photograph(s).
    Stage 1 on-device color shortlist: "{STAGE_1_HINT}". Treat this only as a hint, not as a visual classification.

    ## 1. OPTICAL & MORPHOLOGICAL ATTRIBUTE EXAMINATION
    Carefully evaluate visible features:
    1. Crystal System & Habit: Prismatic, hexagonal, cubic, botryoidal, massive, rhombohedral, fibrous, bladed, tabular, geode/cluster, octahedron, dodecahedron.
    2. Luster & Surface Sheen: Vitreous, adamantine, metallic, sub-metallic, silky, pearly, greasy/waxy, resinous, dull/earthy.
    3. Cleavage vs. Fracture Morphology: Conchoidal fracture vs perfect planar cleavage (cubic, rhombohedral, basal, octahedral).
    4. Color Distribution & Zoning: Base body color vs trace impurities, color zoning, phantom crystals.
    5. Inclusions & Internal Phenomena: Rutile needles, tourmaline silk, pyrite specks, dendrites, gas bubbles/swirls (synthetic/glass).
    6. Optical Phenomena: Labradorescence, adularescence, chatoyancy, asterism, pleochroism, aventurescence.
    7. Specimen Form: Rough crystal, tumbled pebble, cabochon, faceted cut gem, cluster/druzy, polished slab, specimen on matrix.

    ## 2. LOOKALIKE SEPARATION & CONFUSION PAIR CONTRAST
    Actively contrast known lookalike twins before finalizing predictions:
    - Clear Quartz vs Glass / Topaz / Calcite / Selenite (conchoidal fracture & striations vs bubbles/swirls or basal/rhombohedral cleavage).
    - Citrine vs Heat-Treated Amethyst vs Yellow Topaz (uniform yellow throughout vs burnt orange tips on opaque white quartz bases).
    - Amethyst vs Purple Fluorite / Tanzanite / Iolite (trigonal prism & conchoidal fracture vs cubic habit & octahedral cleavage).
    - Turquoise vs Dyed Howlite / Dyed Magnesite / Chrysocolla / Amazonite (natural limonite matrix vs dye pooled in spiderweb fractures).
    - Emerald vs Green Tourmaline / Green Fluorite / Dyed Quartz (hexagonal prism & 3-phase inclusions vs vertical striations & triangular cross-section).
    - Obsidian vs Black Tourmaline (Schorl) vs Black Onyx vs Jet vs Hematite (glassy conchoidal fracture vs longitudinal striations and columnar prism).
    - Moonstone vs Rainbow Moonstone vs Opalite vs White Chalcedony (billowy adularescence vs multi-color schiller vs orange glow synthetic glass).
    - Jade (Nephrite) vs Jadeite vs Serpentine vs Green Aventurine (greasy fibrous toughness vs granular vs soft vs aventurescent platelets).
    - Lapis Lazuli vs Sodalite vs Azurite vs Dumortierite (deep ultramarine with pyrite specks vs royal blue with white nepheline, no pyrite).
    - Malachite vs Chrysocolla vs Dyed Howlite (concentric banded rings vs non-banded teal cyan).
    - Ruby vs Red Spinel vs Almandine Garnet vs Red Glass (hexagonal tabular habit & rutile silk vs octahedrons vs dodecahedrons).
    - Sapphire vs Blue Kyanite vs Tanzanite vs Blue Spinel (hexagonal corundum vs bladed crystals with directional hardness).

    ## 3. SHORTLIST-THEN-SEPARATE RANKING DISCIPLINE, TIE-BREAKS, AND ANTI-DEFAULT RULES
    - Phase 1 Shortlist: Formulate candidate shortlist of top 3 most plausible minerals before committing to rank 1.
    - Phase 2 Separating Contrast: Actively inspect for discriminating diagnostic features to promote a candidate to pred_1 ONLY when visual evidence supports it over lookalikes.
    - Phase 3 Anti-Default Rules: NEVER default to generic common species (Clear Quartz, Glass, Slag, Calcite, Dyed Agate) when specific diagnostic traits exist. For tumbled/cut stones, evaluate luster, cleavage, and color depth.
    - Tie-Breaks: Apply specific physical contrast criteria (heated tips -> Heat-Treated Amethyst, dye pooling -> Dyed Howlite, multi-color flash -> Rainbow Moonstone, pyrite -> Lapis).
    - Candidate Spread Calibration:
      - Confirmed Band (conf_1 = 0.85 - 0.96): conf_1 - conf_2 margin >= 0.60. Never exceed 0.96.
      - Likely Band (conf_1 = 0.55 - 0.84): conf_1 - conf_2 margin = 0.15 - 0.55.
      - Best Guesses Band (conf_1 < 0.55): conf_1 - conf_2 margin < 0.15.

    ## 4. RESPONSE FORMAT
    Return valid JSON in this exact structure without markdown backticks:
    {
      "pred_1": "Primary Mineral Name",
      "conf_1": 0.92,
      "pred_2": "Second Mineral Candidate",
      "conf_2": 0.05,
      "pred_3": "Third Mineral Candidate",
      "conf_3": 0.03,
      "family": "Mineral Family",
      "identified_form": "rough | tumbled | cabochon | cut | cluster | slab",
      "visual_cues": ["cue 1", "cue 2", "cue 3"],
      "lookalike_twin": "Primary lookalike twin species",
      "twin_in_top3": true,
      "separating_tests": [
        {
          "test_name": "Mohs Hardness Scratch Test",
          "procedure": "Attempt to scratch standard glass plate (Mohs 5.5).",
          "diagnostic_rule": "Amethyst scratches glass; Fluorite cannot."
        }
      ],
      "reasoning": "Detailed geological explanation applying shortlist-then-separate logic, anti-default validation, and tie-break reasoning."
    }
    """
    
    /// SHA-256 hash identifying the exact version of the prompt used during inference.
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
    
    private let apiKeyAccount = "GemIDScanner_GeminiAPIKey"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// True if the user manually saved a custom key in Keychain.
    public var hasCustomUserKey: Bool {
        customUserKey != nil
    }

    /// User-supplied key stored in Keychain on this device.
    public var customUserKey: String? {
        var query = keychainQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !str.isEmpty else { return nil }
        return str
    }

    /// Default bundled key from Info.plist (build injection), GeminiConfig.plist, or environment.
    public var bundledKey: String? {
        // 1. Info.plist injected at build time (e.g. INFOPLIST_KEY_GEMINI_API_KEY)
        if let infoKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String {
            let trimmed = infoKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }

        // 2. Embedded GeminiConfig.plist in the app bundle
        if let path = Bundle.main.path(forResource: "GeminiConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let configKey = dict["GEMINI_API_KEY"] as? String {
            let trimmed = configKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        // 3. Process environment (debugging / simulator)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            let trimmed = envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    /// Whether any usable Gemini Vision API key is currently available.
    public var isVisionAvailable: Bool {
        guard let key = apiKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Active API key: prioritizes custom Keychain override, falling back to bundled key.
    public var apiKey: String? {
        get {
            return customUserKey ?? bundledKey
        }
        set {
            SecItemDelete(keychainQuery as CFDictionary)
            if let value = newValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                var query = keychainQuery
                query[kSecValueData as String] = Data(value.utf8)
                query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                SecItemAdd(query as CFDictionary, nil)
            }
        }
    }

    private var keychainQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "GemIDScanner",
            kSecAttrAccount as String: apiKeyAccount
        ]
    }
    
    /// Analyzes a specimen image with Stage 2 second-opinion reasoning, capped with a 6.0s timeout.
    public func analyzeSecondOpinion(image: UIImage, stage1Candidate: String) async throws -> Stage2Inference {
        let cloudAnalysisEnabled = UserDefaults.standard.object(forKey: "GemIDScanner_HighPrecisionCloud") as? Bool ?? true
        guard cloudAnalysisEnabled else {
            return offlineShortlist(
                stage1Candidate: stage1Candidate,
                explanation: "Gemini vision analysis is turned off."
            )
        }

        // If an explicit Gemini API key is configured, perform live network request
        if let key = apiKey, !key.isEmpty {
            return try await performGeminiVisionRequest(image: image, apiKey: key, stage1Hint: stage1Candidate)
        }
        
        return offlineShortlist(
            stage1Candidate: stage1Candidate,
            explanation: "No Gemini API key is configured."
        )
    }
    
    // MARK: - Live Gemini API Call
    private func performGeminiVisionRequest(image: UIImage, apiKey: String, stage1Hint: String) async throws -> Stage2Inference {
        guard let jpegData = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(domain: "GeminiVisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image."])
        }
        
        let base64String = jpegData.base64EncodedString()
        guard var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.modelName):generateContent") else {
            throw NSError(domain: "GeminiVisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint."])
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw NSError(domain: "GeminiVisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint."])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        
        let promptText = Self.promptTemplate.replacingOccurrences(of: "{STAGE_1_HINT}", with: stage1Hint)
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText],
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64String
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "topP": 0.95,
                "responseMimeType": "application/json"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "GeminiVisionService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gemini API error."])
        }
        
        // Parse Gemini response structure
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let rawText = firstPart["text"] as? String {
            
            let cleanJson = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let parsedData = cleanJson.data(using: .utf8),
               let parsedDict = try JSONSerialization.jsonObject(with: parsedData) as? [String: Any] {
                
                guard let name = (parsedDict["pred_1"] as? String ?? parsedDict["topMineralName"] as? String),
                      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw NSError(domain: "GeminiVisionService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini response did not contain a primary mineral identification."])
                }
                let score = parsedDict["conf_1"] as? Double
                    ?? parsedDict["confidenceScore"] as? Double
                    ?? 0.50
                let pred2 = parsedDict["pred_2"] as? String
                let conf2 = parsedDict["conf_2"] as? Double
                let pred3 = parsedDict["pred_3"] as? String
                let conf3 = parsedDict["conf_3"] as? Double
                let family = parsedDict["family"] as? String
                let identifiedForm = parsedDict["identified_form"] as? String
                
                let reasoning = parsedDict["reasoning"] as? String
                    ?? "Multimodal visual confirmation based on surface geometry and luster."
                let visualCues = parsedDict["visual_cues"] as? [String]
                    ?? parsedDict["visualCues"] as? [String]
                    ?? []
                
                var tests: [String] = []
                if let separatingArray = parsedDict["separating_tests"] as? [[String: Any]] {
                    for testDict in separatingArray {
                        if let testName = testDict["test_name"] as? String,
                           let rule = testDict["diagnostic_rule"] as? String {
                            tests.append("\(testName): \(rule)")
                        } else if let testName = testDict["test_name"] as? String {
                            tests.append(testName)
                        }
                    }
                } else if let simpleTests = parsedDict["suggestedTests"] as? [String] {
                    tests = simpleTests
                }
                
                let lookalike = parsedDict["lookalike_twin"] as? String
                    ?? parsedDict["lookalikeDisambiguation"] as? String
                
                let rawName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedName = MineralDatabase.shared.find(byName: rawName)?.name ?? rawName
                let resolvedPred2 = pred2.flatMap { MineralDatabase.shared.find(byName: $0)?.name ?? $0 }
                let resolvedPred3 = pred3.flatMap { MineralDatabase.shared.find(byName: $0)?.name ?? $0 }
                
                return Stage2Inference(
                    topMineralName: resolvedName,
                    score: min(max(score, 0.05), 0.96),
                    reasoning: reasoning,
                    visualCuesObserved: visualCues,
                    suggestedTests: tests,
                    lookalikeDisambiguation: lookalike,
                    candidate2Name: resolvedPred2,
                    candidate2Score: conf2 != nil ? min(max(conf2!, 0.01), 0.96) : nil,
                    candidate3Name: resolvedPred3,
                    candidate3Score: conf3 != nil ? min(max(conf3!, 0.01), 0.96) : nil,
                    family: family,
                    identifiedForm: identifiedForm
                )
            }
        }
        
        throw NSError(domain: "GeminiVisionService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Gemini returned an unreadable identification response."])
    }
    
    // MARK: - Offline Shortlist
    private func offlineShortlist(stage1Candidate: String, explanation: String) -> Stage2Inference {
        let mineral = MineralDatabase.shared.find(byName: stage1Candidate)
        
        let name = mineral?.name ?? stage1Candidate
        let lookalikes = mineral?.topLookalikes
        let primaryLookalike = lookalikes?.first
        let secondaryLookalike = lookalikes != nil && lookalikes!.count > 1 ? lookalikes![1] : nil
        
        let reasoning = "\(explanation) \(name) is only an on-device color shortlist; verify the specimen with physical tests."
        let cues = [
            "Central image color compared with the catalog color range",
            "Luster and fracture cannot be verified without vision analysis",
            "Use physical tests to confirm the specimen"
        ]
        
        let tests = mineral?.ruleOutTests.prefix(2).map { String($0) } ?? ["Mohs Hardness Scratch Test", "Ceramic Streak Tile Test"]
        let disambig = primaryLookalike != nil ? "Distinguish from \(primaryLookalike!.mineralName): \(primaryLookalike!.separatingTest)" : nil
        
        return Stage2Inference(
            topMineralName: name,
            score: 0.25,
            reasoning: reasoning,
            visualCuesObserved: cues,
            suggestedTests: tests,
            lookalikeDisambiguation: disambig,
            candidate2Name: primaryLookalike?.mineralName,
            candidate2Score: 0.15,
            candidate3Name: secondaryLookalike?.mineralName,
            candidate3Score: 0.10,
            family: mineral?.family,
            identifiedForm: "rough"
        )
    }
}
