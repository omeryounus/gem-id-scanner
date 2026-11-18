import Foundation

/// A single candidate match for a mineral identification.
public struct CandidateItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String { mineralName }
    public let mineralName: String
    public let score: Double // 0.0 to 1.0
    public let confidenceBand: ConfidenceBand
    public let keyCharacteristics: [String]
    public let separatingTestSummary: String?
    public let ruleInAction: String?
    
    public init(
        mineralName: String,
        score: Double,
        keyCharacteristics: [String] = [],
        separatingTestSummary: String? = nil,
        ruleInAction: String? = nil
    ) {
        self.mineralName = mineralName
        self.score = min(max(score, 0.0), 0.96) // Hard cap at 96%
        self.confidenceBand = ConfidenceBand(score: self.score)
        self.keyCharacteristics = keyCharacteristics
        self.separatingTestSummary = separatingTestSummary
        self.ruleInAction = ruleInAction
    }
}

/// Stage 1 on-device inference result.
public struct Stage1Inference: Codable, Hashable, Sendable {
    public let topMineralName: String
    public let score: Double
    public let inferenceDurationMs: Double
    public let allProbabilities: [String: Double]
    
    public init(topMineralName: String, score: Double, inferenceDurationMs: Double, allProbabilities: [String : Double] = [:]) {
        self.topMineralName = topMineralName
        self.score = score
        self.inferenceDurationMs = inferenceDurationMs
        self.allProbabilities = allProbabilities
    }
}

/// Stage 2 multimodal vision analysis result.
public struct Stage2Inference: Codable, Hashable, Sendable {
    public let topMineralName: String
    public let score: Double
    public let reasoning: String
    public let visualCuesObserved: [String]
    public let suggestedTests: [String]
    public let lookalikeDisambiguation: String?
    public let candidate2Name: String?
    public let candidate2Score: Double?
    public let candidate3Name: String?
    public let candidate3Score: Double?
    public let family: String?
    public let identifiedForm: String?
    /// `on_device`, `cloud_text`, `cloud_vision`, or `shortlist`.
    public let inferenceRoute: String
    public let modelVersion: String
    public let photoLeftDevice: Bool

    /// One line for the result screen. Names the engine that produced this rank.
    public var engineSummary: String {
        switch inferenceRoute {
        case "on_device":
            return photoLeftDevice
                ? "Firebase AI Logic · Apple Intelligence on this iPhone. The photo was sent to Gemini."
                : "Firebase AI Logic · Apple Intelligence on this iPhone. The photo stayed on the device."
        case "cloud_vision":
            return "Firebase AI Logic · Gemini examined the photo\(modelVersion.isEmpty ? "" : " (\(modelVersion))")."
        case "cloud_text":
            return photoLeftDevice
                ? "Firebase AI Logic · Gemini ranked the color brief. The photo was also sent to Gemini."
                : "Firebase AI Logic · Gemini ranked the on-device color brief. The photo stayed on the device."
        default:
            return "Color shortlist only. Firebase AI Logic did not return a catalog rank."
        }
    }
    
    public init(
        topMineralName: String,
        score: Double,
        reasoning: String,
        visualCuesObserved: [String] = [],
        suggestedTests: [String] = [],
        lookalikeDisambiguation: String? = nil,
        candidate2Name: String? = nil,
        candidate2Score: Double? = nil,
        candidate3Name: String? = nil,
        candidate3Score: Double? = nil,
        family: String? = nil,
        identifiedForm: String? = nil,
        inferenceRoute: String = "shortlist",
        modelVersion: String = "",
        photoLeftDevice: Bool = false
    ) {
        self.topMineralName = topMineralName
        self.score = score
        self.reasoning = reasoning
        self.visualCuesObserved = visualCuesObserved
        self.suggestedTests = suggestedTests
        self.lookalikeDisambiguation = lookalikeDisambiguation
        self.candidate2Name = candidate2Name
        self.candidate2Score = candidate2Score
        self.candidate3Name = candidate3Name
        self.candidate3Score = candidate3Score
        self.family = family
        self.identifiedForm = identifiedForm
        self.inferenceRoute = inferenceRoute
        self.modelVersion = modelVersion
        self.photoLeftDevice = photoLeftDevice
    }

    /// The vision call was attempted, so the result must not say the photo stayed on the iPhone.
    public func markingPhotoSent() -> Stage2Inference {
        Stage2Inference(
            topMineralName: topMineralName,
            score: score,
            reasoning: reasoning,
            visualCuesObserved: visualCuesObserved,
            suggestedTests: suggestedTests,
            lookalikeDisambiguation: lookalikeDisambiguation,
            candidate2Name: candidate2Name,
            candidate2Score: candidate2Score,
            candidate3Name: candidate3Name,
            candidate3Score: candidate3Score,
            family: family,
            identifiedForm: identifiedForm,
            inferenceRoute: inferenceRoute,
            modelVersion: modelVersion,
            photoLeftDevice: true
        )
    }
}

/// Comprehensive two-stage identification result output by the IdentificationCoordinator.
public struct IdentificationResult: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public let timestamp: Date
    public let topCandidate: CandidateItem
    public let mergedConfidence: Double
    public let confidenceBand: ConfidenceBand
    public let stage1Prediction: Stage1Inference?
    public let stage2Prediction: Stage2Inference?
    public let candidates: [CandidateItem]
    public let separatingTests: [String]
    public let imageQualityNotice: String?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        topCandidate: CandidateItem,
        mergedConfidence: Double,
        stage1Prediction: Stage1Inference? = nil,
        stage2Prediction: Stage2Inference? = nil,
        candidates: [CandidateItem] = [],
        separatingTests: [String] = [],
        imageQualityNotice: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.topCandidate = topCandidate
        let clamped = min(max(mergedConfidence, 0.0), 0.96) // Capped at 96%
        self.mergedConfidence = clamped
        self.confidenceBand = ConfidenceBand(score: clamped)
        self.stage1Prediction = stage1Prediction
        self.stage2Prediction = stage2Prediction
        self.candidates = candidates
        self.separatingTests = separatingTests
        self.imageQualityNotice = imageQualityNotice
    }
}
