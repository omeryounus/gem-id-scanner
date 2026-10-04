import Foundation

/// Mineral category grouping for database classification and filter exploration.
public enum MineralCategory: String, Codable, CaseIterable, Sendable {
    case quartzFamily = "Quartz Family"
    case everydayFinds = "Everyday Finds"
    case collectorStaples = "Collector Staples"
    case shopRegulars = "Shop Regulars"
    case colorAndFlash = "Color & Flash"
    
    public var icon: String {
        switch self {
        case .quartzFamily: return "hexagon.fill"
        case .everydayFinds: return "leaf.fill"
        case .collectorStaples: return "cube.transparent.fill"
        case .shopRegulars: return "bag.fill"
        case .colorAndFlash: return "sparkle"
        }
    }
}

/// Physical specimen forms in which a mineral commonly appears.
public enum MineralForm: String, Codable, CaseIterable, Sendable {
    case rough = "Rough"
    case tumbled = "Tumbled"
    case cut = "Faceted / Cut"
    case cabochon = "Cabochon"
    case geode = "Geode / Cluster"
    case carved = "Carved"
}

/// Represents complete encyclopedia identity and gemological specs for a mineral.
public struct Mineral: Identifiable, Codable, Hashable, Sendable {
    public var id: String { name }
    
    // Core Identity
    public let name: String
    public let alternativeNames: [String]
    public let category: MineralCategory
    public let family: String
    public let chemicalFormula: String
    public let crystalSystem: String
    
    // Physical & Optical Properties
    public let mohsHardness: String
    public let minHardness: Double
    public let maxHardness: Double
    public let specificGravity: String
    public let luster: String
    public let streak: String
    public let cleavage: String
    public let fracture: String
    public let transparency: String
    public let refractiveIndex: String?
    
    // Color & Form
    public let colorRange: [String]
    public let commonForms: [MineralForm]
    
    // Distinctions & Tests
    public let topLookalikes: [Lookalike]
    public let ruleOutTests: [String]
    public let careWarnings: [String]
    
    // Description & Lore
    public let summary: String
    public let geologicalOrigin: String
    public let rarityAndOccurrence: String
    public let safetyAndHandling: String
    public let imageName: String
    
    public init(
        name: String,
        alternativeNames: [String] = [],
        category: MineralCategory,
        family: String,
        chemicalFormula: String,
        crystalSystem: String,
        mohsHardness: String,
        minHardness: Double,
        maxHardness: Double,
        specificGravity: String,
        luster: String,
        streak: String,
        cleavage: String,
        fracture: String,
        transparency: String,
        refractiveIndex: String? = nil,
        colorRange: [String],
        commonForms: [MineralForm],
        topLookalikes: [Lookalike],
        ruleOutTests: [String],
        careWarnings: [String],
        summary: String,
        geologicalOrigin: String,
        rarityAndOccurrence: String,
        safetyAndHandling: String = "Non-toxic under normal handling.",
        imageName: String? = nil
    ) {
        self.name = name
        self.alternativeNames = alternativeNames
        self.category = category
        self.family = family
        self.chemicalFormula = chemicalFormula
        self.crystalSystem = crystalSystem
        self.mohsHardness = mohsHardness
        self.minHardness = minHardness
        self.maxHardness = maxHardness
        self.specificGravity = specificGravity
        self.luster = luster
        self.streak = streak
        self.cleavage = cleavage
        self.fracture = fracture
        self.transparency = transparency
        self.refractiveIndex = refractiveIndex
        self.colorRange = colorRange
        self.commonForms = commonForms
        self.topLookalikes = topLookalikes
        self.ruleOutTests = ruleOutTests
        self.careWarnings = careWarnings
        self.summary = summary
        self.geologicalOrigin = geologicalOrigin
        self.rarityAndOccurrence = rarityAndOccurrence
        self.safetyAndHandling = safetyAndHandling
        self.imageName = imageName ?? name.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}
