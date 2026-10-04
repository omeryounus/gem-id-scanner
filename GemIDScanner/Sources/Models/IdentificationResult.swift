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
    
    public init(
        topMineralName: String,
        score: Double,
        reasoning: String,
        visualCuesObserved: [String] = [],
        suggestedTests: [String] = [],
        lookalikeDisambiguation: String? = nil
    ) {
        self.topMineralName = topMineralName
        self.score = score
        self.reasoning = reasoning
        self.visualCuesObserved = visualCuesObserved
        self.suggestedTests = suggestedTests
        self.lookalikeDisambiguation = lookalikeDisambiguation
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
