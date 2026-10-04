import Foundation

@main
struct ColorRankingRegression {
    static func main() {
        let catalog: [(name: String, colorRanges: [String])] = [
            ("Ruby", ["Red", "Crimson"]),
            ("Sapphire", ["Blue", "Navy"]),
            ("Malachite", ["Green", "Forest Green"]),
            ("Aqua Tourmaline", ["Blue-green"]),
            ("Citrine", ["Yellow", "Golden"])
        ]

        let profiles = [
            MineralColorScorer.Profile(hue: 0, saturation: 0.85, brightness: 0.52),
            MineralColorScorer.Profile(hue: 220, saturation: 0.85, brightness: 0.52),
            MineralColorScorer.Profile(hue: 120, saturation: 0.85, brightness: 0.52),
            MineralColorScorer.Profile(hue: 180, saturation: 0.85, brightness: 0.52)
        ]
        let rankings = profiles.map { MineralColorScorer.rank(profile: $0, minerals: catalog) }
        let winners = rankings.compactMap(\.first?.name)

        precondition(winners == ["Ruby", "Sapphire", "Malachite", "Aqua Tourmaline"], "Distinct specimen colors should produce distinct catalog leaders: \(winners)")
        precondition(Set(winners).count == profiles.count, "Different color profiles must not share one fixed leader.")
        precondition(rankings.allSatisfy { $0.allSatisfy { (0.25...0.5).contains($0.score) } }, "Color-only scores must remain low confidence.")
        precondition(
            MineralColorScorer.rank(profile: profiles[0], minerals: catalog).map(\.name) == rankings[0].map(\.name),
            "Ranking must be deterministic for the same image profile."
        )

        print("Color ranking regression passed: \(winners.joined(separator: ", ")); scores remain <= 0.50 and rankings are deterministic.")
    }
}