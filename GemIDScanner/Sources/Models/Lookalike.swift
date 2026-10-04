import Foundation

/// Defines a visual or physical lookalike for a given mineral,
/// along with definitive diagnostic separating tests to tell them apart.
public struct Lookalike: Identifiable, Codable, Hashable, Sendable {
    public var id: String { mineralName }
    
    /// The name of the lookalike mineral
    public let mineralName: String
    
    /// Key visual distinction
    public let visualDifference: String
    
    /// Primary physical or chemical test to separate the two
    public let separatingTest: String
    
    /// Hardness difference comparison (e.g., "Calcite (3) scratches easily; Quartz (7) scratches glass")
    public let hardnessComparison: String?
    
    /// Streak or acid reaction difference if applicable
    public let diagnosticReaction: String?
    
    public init(
        mineralName: String,
        visualDifference: String,
        separatingTest: String,
        hardnessComparison: String? = nil,
        diagnosticReaction: String? = nil
    ) {
        self.mineralName = mineralName
        self.visualDifference = visualDifference
        self.separatingTest = separatingTest
        self.hardnessComparison = hardnessComparison
        self.diagnosticReaction = diagnosticReaction
    }
}
