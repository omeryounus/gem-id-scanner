import Foundation
import UIKit

public struct MineralCorrectionItem: Identifiable, Codable, Sendable {
    public var id: UUID
    public let timestamp: Date
    public let photoData: Data?
    public let predictedMineral: String
    public let userCorrectedMineral: String
    public let userNotes: String
    public let confidenceAtPrediction: Double
    public var isUploaded: Bool
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        photoData: Data? = nil,
        predictedMineral: String,
        userCorrectedMineral: String,
        userNotes: String = "",
        confidenceAtPrediction: Double = 0.5,
        isUploaded: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.photoData = photoData
        self.predictedMineral = predictedMineral
        self.userCorrectedMineral = userCorrectedMineral
        self.userNotes = userNotes
        self.confidenceAtPrediction = confidenceAtPrediction
        self.isUploaded = isUploaded
    }
}

/// Service managing offline queue of user corrections to improve AI accuracy over time.
@MainActor
public final class CorrectionFeedbackService: ObservableObject {
    public static let shared = CorrectionFeedbackService()
    
    private let queueDefaultsKey = "GemIDScanner_CorrectionQueue"
    @Published public var queuedCorrections: [MineralCorrectionItem] = []
    @Published public var isSyncing: Bool = false
    @Published public var modelImprovementOptIn: Bool = true {
        didSet {
            UserDefaults.standard.set(modelImprovementOptIn, forKey: "GemIDScanner_OptInModelImprovement")
        }
    }
    
    public var pendingCount: Int {
        queuedCorrections.filter { !$0.isUploaded }.count
    }
    
    public init() {
        if UserDefaults.standard.object(forKey: "GemIDScanner_OptInModelImprovement") != nil {
            self.modelImprovementOptIn = UserDefaults.standard.bool(forKey: "GemIDScanner_OptInModelImprovement")
        } else {
            self.modelImprovementOptIn = true
        }
        loadQueue()
    }
    
    public func submitCorrection(photoData: Data? = nil, predicted: String, corrected: String, notes: String, confidence: Double) {
        let item = MineralCorrectionItem(
            photoData: photoData,
            predictedMineral: predicted,
            userCorrectedMineral: corrected,
            userNotes: notes,
            confidenceAtPrediction: confidence,
            isUploaded: false
        )
        queuedCorrections.insert(item, at: 0)
        saveQueue()
    }
    
    public func deleteCorrection(id: UUID) {
        queuedCorrections.removeAll { $0.id == id }
        saveQueue()
    }
    
    public func delete(at offsets: IndexSet) {
        queuedCorrections.remove(atOffsets: offsets)
        saveQueue()
    }
    
    public func clearUploadedCorrections() {
        queuedCorrections.removeAll { $0.isUploaded }
        saveQueue()
    }
    
    public func clearAll() {
        queuedCorrections.removeAll()
        saveQueue()
    }
    
    /// Simulates or executes asynchronous background sync of pending corrections to the model training pipeline.
    @discardableResult
    public func syncPendingCorrections() async -> Int {
        guard !isSyncing else { return 0 }
        isSyncing = true
        defer { isSyncing = false }
        
        // Emulate network latency for telemetry sync
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        var count = 0
        for i in 0..<queuedCorrections.count {
            if !queuedCorrections[i].isUploaded {
                queuedCorrections[i].isUploaded = true
                count += 1
            }
        }
        saveQueue()
        return count
    }
    
    private func saveQueue() {
        if let data = try? JSONEncoder().encode(queuedCorrections) {
            UserDefaults.standard.set(data, forKey: queueDefaultsKey)
        }
    }
    
    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: queueDefaultsKey),
           let list = try? JSONDecoder().decode([MineralCorrectionItem].self, from: data) {
            self.queuedCorrections = list
        }
    }
}
