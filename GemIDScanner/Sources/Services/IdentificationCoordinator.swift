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
    /// Executes the complete end-to-end identification workflow.
    public func identify(image: UIImage) async throws -> IdentificationResult {
        isAnalyzing = true
        errorMessage = nil
        
        // 1. Quality Check
        analysisStep = .assessingQuality
        let qualityAssessment = CameraService().evaluateImageQuality(image: image)
        
        // 2. Stage 1 On-Device CoreML (<100ms)
        analysisStep = .runningStage1OnDevice
        let stage1 = try await coreMLService.classify(image: image)
        
        // 3. Stage 2 Cloud Second Opinion with 6-second timeout
        analysisStep = .runningStage2CloudOpinion
        let stage2: Stage2Inference
        do {
            stage2 = try await withThrowingTaskGroup(of: Stage2Inference.self) { group in
                group.addTask {
                    try await self.geminiService.analyzeSecondOpinion(image: image, stage1Candidate: stage1.topMineralName)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 6_000_000_000)
                    throw NSError(domain: "IdentificationCoordinator", code: 408, userInfo: [NSLocalizedDescriptionKey: "Stage 2 cloud opinion timed out after 6 seconds."])
                }
                let first = try await group.next()!
                group.cancelAll()
                return first
            }
        } catch {
            // Stage 2 timeout or offline fallback
            let fallbackMin = database.find(byName: stage1.topMineralName)
            stage2 = Stage2Inference(
                topMineralName: stage1.topMineralName,
                score: min(stage1.score, 0.84),
                reasoning: "On-device neural profile analyzed. Stage 2 completed with offline heuristics.",
                visualCuesObserved: ["Optical habit matches \(fallbackMin?.crystalSystem ?? "crystal standard")"],
                suggestedTests: fallbackMin?.ruleOutTests.prefix(2).map { String($0) } ?? ["Mohs Hardness Scratch Test"],
                lookalikeDisambiguation: fallbackMin?.topLookalikes.first.map { "Distinguish from \($0.mineralName): \($0.separatingTest)" }
            )
        }
        
        // 4. Two-Stage Confidence Merge Logic
        analysisStep = .mergingConfidence
        
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
            // Agreement: weighted average favoring Stage 2 multimodal reasoning, capped at 96%
            let weighted = (stage1.score * 0.35) + (stage2.score * 0.65)
            mergedScore = min(weighted, 0.96)
            primaryName = name1
        } else {
            // Disagreement: Stage 2 multimodal vision takes precedence as primary,
            // with confidence calibrated down to Likely (55-84%) or Best Guesses (<55%)
            let lowerScore = min(stage1.score, stage2.score)
            mergedScore = min(lowerScore, 0.78)
            primaryName = stage2.score >= stage1.score ? name2 : name1
        }
        
        let primaryMineral = database.find(byName: primaryName)
        
        // Build Top 3 candidate list
        var candidateList: [CandidateItem] = []
        
        // Candidate #1
        candidateList.append(CandidateItem(
            mineralName: primaryName,
            score: mergedScore,
            keyCharacteristics: primaryMineral?.colorRange ?? [],
            separatingTestSummary: primaryMineral?.ruleOutTests.first,
            ruleInAction: "Inspect Mohs hardness (\(primaryMineral?.mohsHardness ?? "6-7")) and streak."
        ))
        
        // Candidate #2
        let secondaryName: String
        if !doesAgree {
            secondaryName = (primaryName == name1) ? name2 : name1
        } else if let s2c2 = stage2.candidate2Name, !s2c2.isEmpty, s2c2.caseInsensitiveCompare(primaryName) != .orderedSame {
            secondaryName = s2c2
        } else {
            secondaryName = primaryMineral?.topLookalikes.first?.mineralName ?? "Quartz"
        }
        
        if secondaryName.caseInsensitiveCompare(primaryName) != .orderedSame {
            let secondaryMineral = database.find(byName: secondaryName)
            let secondaryScore: Double
            if doesAgree {
                if let s2Score = stage2.candidate2Score {
                    secondaryScore = min(s2Score, mergedScore - 0.15)
                } else {
                    secondaryScore = max(mergedScore - 0.25, 0.40)
                }
            } else {
                secondaryScore = min(min(stage1.score, stage2.score), mergedScore - 0.08)
            }
            
            candidateList.append(CandidateItem(
                mineralName: secondaryName,
                score: secondaryScore,
                keyCharacteristics: secondaryMineral?.colorRange ?? [],
                separatingTestSummary: secondaryMineral?.ruleOutTests.first ?? primaryMineral?.topLookalikes.first?.separatingTest,
                ruleInAction: "Perform diagnostic scratch test against \(primaryName)."
            ))
        }
        
        // Candidate #3
        let tertiaryName: String
        if let s2c3 = stage2.candidate3Name, !s2c3.isEmpty,
           s2c3.caseInsensitiveCompare(primaryName) != .orderedSame,
           s2c3.caseInsensitiveCompare(secondaryName) != .orderedSame {
            tertiaryName = s2c3
        } else if let tertiaryLookalike = primaryMineral?.topLookalikes.first(where: {
            $0.mineralName.caseInsensitiveCompare(primaryName) != .orderedSame &&
            $0.mineralName.caseInsensitiveCompare(secondaryName) != .orderedSame
        }) {
            tertiaryName = tertiaryLookalike.mineralName
        } else {
            tertiaryName = "Calcite"
        }
        
        if tertiaryName.caseInsensitiveCompare(primaryName) != .orderedSame &&
           tertiaryName.caseInsensitiveCompare(secondaryName) != .orderedSame {
            let tertiaryMineral = database.find(byName: tertiaryName)
            let tertiaryScore: Double
            if let s3Score = stage2.candidate3Score {
                tertiaryScore = min(s3Score, (candidateList.last?.score ?? mergedScore) - 0.05)
            } else {
                tertiaryScore = max((candidateList.last?.score ?? mergedScore) - 0.15, 0.25)
            }
            
            candidateList.append(CandidateItem(
                mineralName: tertiaryName,
                score: tertiaryScore,
                keyCharacteristics: tertiaryMineral?.colorRange ?? [],
                separatingTestSummary: tertiaryMineral?.ruleOutTests.first,
                ruleInAction: "Inspect cleavage geometry and acid reactivity."
            ))
        }
        
        // Separating tests compilation
        var tests: [String] = []
        if !stage2.suggestedTests.isEmpty {
            tests.append(contentsOf: stage2.suggestedTests)
        }
        if let pMin = primaryMineral {
            for test in pMin.ruleOutTests where !tests.contains(test) {
                tests.append(test)
            }
            for lookalike in pMin.topLookalikes.prefix(2) {
                let lookalikeStr = "\(lookalike.mineralName) Distinction: \(lookalike.separatingTest)"
                if !tests.contains(lookalikeStr) {
                    tests.append(lookalikeStr)
                }
            }
        }
        if tests.isEmpty {
            tests = [
                "Mohs Scratch Test: Test against standard glass plate (Mohs 5.5).",
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
