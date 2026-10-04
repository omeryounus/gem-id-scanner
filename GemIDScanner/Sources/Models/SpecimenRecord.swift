import Foundation
import SwiftData

/// Persistent SwiftData model representing a specimen in the user's personal rock & mineral collection.
@Model
public final class SpecimenRecord {
    @Attribute(.unique)
    public var id: UUID
    
    @Attribute(.externalStorage)
    public var photoData: Data?
    
    public var mineralName: String
    public var confidence: Double
    public var confidenceBandRaw: String
    public var dateAdded: Date
    public var notes: String
    public var weightGrams: Double?
    public var originSource: String?
    public var form: String
    public var isFavorite: Bool
    public var userConfirmed: Bool
    public var customTags: [String]
    
    public var confidenceBand: ConfidenceBand {
        get {
            ConfidenceBand(rawValue: confidenceBandRaw) ?? ConfidenceBand(score: confidence)
        }
        set {
            confidenceBandRaw = newValue.rawValue
        }
    }
    
    public init(
        id: UUID = UUID(),
        photoData: Data? = nil,
        mineralName: String,
        confidence: Double,
        confidenceBand: ConfidenceBand,
        dateAdded: Date = Date(),
        notes: String = "",
        weightGrams: Double? = nil,
        originSource: String? = nil,
        form: String = "Rough",
        isFavorite: Bool = false,
        userConfirmed: Bool = false,
        customTags: [String] = []
    ) {
        self.id = id
        self.photoData = photoData
        self.mineralName = mineralName
        self.confidence = min(max(confidence, 0.0), 0.96)
        self.confidenceBandRaw = confidenceBand.rawValue
        self.dateAdded = dateAdded
        self.notes = notes
        self.weightGrams = weightGrams
        self.originSource = originSource
        self.form = form
        self.isFavorite = isFavorite
        self.userConfirmed = userConfirmed
        self.customTags = customTags
    }
}
