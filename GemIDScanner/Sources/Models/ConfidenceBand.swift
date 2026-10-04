import Foundation
import SwiftUI

/// Categorizes the confidence score of a mineral identification.
///
/// Confidence rules:
/// - Confirmed: 85% - 96% (Never claims 100% due to visual identification limits)
/// - Likely: 55% - 84%
/// - Best Guesses: < 55%
public enum ConfidenceBand: String, Codable, CaseIterable, Sendable {
    case confirmed = "Confirmed"
    case likely = "Likely"
    case bestGuesses = "Best Guesses"
    
    public init(score: Double) {
        let clamped = min(max(score, 0.0), 1.0)
        switch clamped {
        case 0.85...1.0:
            self = .confirmed
        case 0.55..<0.85:
            self = .likely
        default:
            self = .bestGuesses
        }
    }
    
    public var title: String {
        switch self {
        case .confirmed: return "High Match"
        case .likely: return "Likely Match"
        case .bestGuesses: return "Top Possibilities"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .confirmed:
            return "Visual signatures strongly match reference specimens (capped at 96%)."
        case .likely:
            return "Strong visual traits present. Confirm with Mohs or streak test."
        case .bestGuesses:
            return "Visual ambiguity detected. Compare separating physical tests below."
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .confirmed:
            return Color(red: 0.18, green: 0.80, blue: 0.44) // Emerald green
        case .likely:
            return Color(red: 0.95, green: 0.65, blue: 0.15) // Amber gold
        case .bestGuesses:
            return Color(red: 0.92, green: 0.35, blue: 0.35) // Coral red
        }
    }
    
    public var iconName: String {
        switch self {
        case .confirmed: return "checkmark.seal.fill"
        case .likely: return "sparkles"
        case .bestGuesses: return "questionmark.circle.fill"
        }
    }
}
