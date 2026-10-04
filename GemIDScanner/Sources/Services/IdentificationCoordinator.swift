import Foundation
import UIKit
import SwiftUI

/// Orchestrates the two-stage visual identification pipeline:
/// - Stage 1: Fast on-device CoreML / Neural Engine classification (<100ms)
/// - Stage 2: Cloud / Multimodal Gemini Vision second-opinion verification
///
/// Merge Rules:
/// - Agreement: When Stage 1 and Stage 2 predict the same mineral, the confidence score is
///   calculated as a weighted average and capped at a maximum of 96% (0.96) to reflect
///   the gemological limitation that non-destructive optical scans cannot reach 100%.
/// - Disagreement: When Stage 1 and Stage 2 predict different minerals, merged confidence
///   is automatically lowered to the 'Likely' (55-84%) or 'Best Guesses' (<55%) bands,
///   and top lookalike separating tests are promoted for physical verification.
@MainActor
public final class IdentificationCoordinator: ObservableObject {
    public static let shared = IdentificationCoordinator()
    
    @Published public var isAnalyzing = false
    @Published public var analysisStep: AnalysisProgressStep = .idle
    @Published public var lastResult: IdentificationResult?
    @Published public var errorMessage: String?
    
    public enum AnalysisProgressStep: Equatable, Sendable {
        case idle
        case assessingQuality
        case runningStage1OnDevice
        case runningStage2CloudOpinion
        case mergingConfidence
        case complete
        
        public var title: String {
            switch self {
            case .idle: return "Ready"
            case .assessingQuality: return "Evaluating image lighting & sharpness..."
            case .runningStage1OnDevice: return "Running Stage 1 On-Device Neural Classifier (<100ms)..."
            case .runningStage2CloudOpinion: return "Stage 2: Consulting Gemini Vision second opinion..."
            case .mergingConfidence: return "Merging two-stage predictions & calculating confidence..."
            case .complete: return "Identification Complete"
            }
        }
    }
    
    private let coreMLService: CoreMLClassifierService
    private let geminiService: GeminiVisionService
    private let database: MineralDatabase
    
    public init(
        coreMLService: CoreMLClassifierService = .shared,
        geminiService: GeminiVisionService = .shared,
        database: MineralDatabase = .shared
    ) {
        self.coreMLService = coreMLService
        self.geminiService = geminiService
        self.database = database
    }
    
    /// Executes the complete end-to-end identification workflow.
    public func identify(image: UIImage) async throws -> IdentificationResult {
        isAnalyzing = true
        errorMessage = nil
        
        // 1. Quality Check
        analysisStep = .assessingQuality
        let qualityAssessment = CameraService().evaluateImageQuality(image: image)
        try await Task.sleep(nanoseconds: 120_000_000)
        
        // 2. Stage 1 On-Device CoreML
        analysisStep = .runningStage1OnDevice
        let stage1 = try await coreMLService.classify(image: image)
        
        // 3. Stage 2 Cloud Second Opinion
        analysisStep = .runningStage2CloudOpinion
        let stage2 = try await geminiService.analyzeSecondOpinion(image: image, stage1Candidate: stage1.topMineralName)
        
        // 4. Two-Stage Confidence Merge Logic
        analysisStep = .mergingConfidence
        try await Task.sleep(nanoseconds: 150_000_000)
        
        let result = mergeTwoStagePredictions(
            stage1: stage1,
            stage2: stage2,
            qualityNotice: qualityAssessment.summary
        )
        
        self.lastResult = result
        self.analysisStep = .complete
        self.isAnalyzing = false
        
        return result
    }
    
    // MARK: - Two-Stage Merge Engine
    private func mergeTwoStagePredictions(
        stage1: Stage1Inference,
        stage2: Stage2Inference,
        qualityNotice: String?
    ) -> IdentificationResult {
        let name1 = stage1.topMineralName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name2 = stage2.topMineralName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let doesAgree = name1.caseInsensitiveCompare(name2) == .orderedSame
        let mergedScore: Double
        let primaryName: String
        
        if doesAgree {
            // Stage 1 & 2 Agree: Weighted average (40% Stage 1, 60% Stage 2) capped at 96%
            let rawAvg = (stage1.score * 0.40) + (stage2.score * 0.60)
            mergedScore = min(rawAvg, 0.96) // Capped at 96%
            primaryName = name1
        } else {
            // Disagreement: Lower score to Likely or Best Guesses
            let maxScore = max(stage1.score, stage2.score)
            mergedScore = min(maxScore * 0.72, 0.78) // Drops down into 55-78% Likely or lower
            primaryName = stage2.score >= stage1.score ? name2 : name1
        }
        
        let primaryMineral = database.find(byName: primaryName)
        
        // Build candidate list
        var candidateList: [CandidateItem] = []
        
        // Top candidate
        candidateList.append(CandidateItem(
            mineralName: primaryName,
            score: mergedScore,
            keyCharacteristics: primaryMineral?.colorRange ?? [],
            separatingTestSummary: primaryMineral?.ruleOutTests.first,
            ruleInAction: "Inspect Mohs hardness (\(primaryMineral?.mohsHardness ?? "6-7")) and streak."
        ))
        
        // If disagreed, append alternate top pick as Candidate #2
        let secondaryName = doesAgree ? (primaryMineral?.topLookalikes.first?.mineralName ?? "Quartz") : (primaryName == name1 ? name2 : name1)
        if secondaryName != primaryName {
            let secondaryMineral = database.find(byName: secondaryName)
            let secondaryScore = doesAgree ? max(mergedScore - 0.22, 0.45) : min(min(stage1.score, stage2.score), mergedScore - 0.08)
            candidateList.append(CandidateItem(
                mineralName: secondaryName,
                score: secondaryScore,
                keyCharacteristics: secondaryMineral?.colorRange ?? [],
                separatingTestSummary: secondaryMineral?.ruleOutTests.first,
                ruleInAction: "Perform diagnostic scratch test against \(primaryName)."
            ))
        }
        
        // Candidate #3 (Lookalike from database)
        if let tertiaryLookalike = primaryMineral?.topLookalikes.first(where: { $0.mineralName != secondaryName }) {
            let tertiaryMineral = database.find(byName: tertiaryLookalike.mineralName)
            candidateList.append(CandidateItem(
                mineralName: tertiaryLookalike.mineralName,
                score: max(mergedScore - 0.38, 0.32),
                keyCharacteristics: tertiaryMineral?.colorRange ?? [],
                separatingTestSummary: tertiaryLookalike.separatingTest,
                ruleInAction: tertiaryLookalike.separatingTest
            ))
        }
        
        // Separating tests compilation
        var tests: [String] = []
        if let pMin = primaryMineral {
            tests.append(contentsOf: pMin.ruleOutTests)
            for lookalike in pMin.topLookalikes.prefix(2) {
                tests.append("\(lookalike.mineralName) Distinction: \(lookalike.separatingTest)")
            }
        } else {
            tests = [
                "Mohs Scratch Test: Test against common hardness benchmarks.",
                "Ceramic Streak Tile: Drag across unglazed tile to observe powdered streak.",
                "Dilute Acid / Vinegar: Test 1 drop of vinegar for CO₂ fizzing."
            ]
        }
        
        let topCandidate = candidateList[0]
        
        return IdentificationResult(
            topCandidate: topCandidate,
            mergedConfidence: mergedScore,
            stage1Prediction: stage1,
            stage2Prediction: stage2,
            candidates: candidateList,
            separatingTests: tests,
            imageQualityNotice: qualityNotice
        )
    }
}
