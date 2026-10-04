import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreML)
import CoreML
import Vision
#endif

#if canImport(UIKit)
/// Stage 1 on-device visual shortlist.
///
/// The current implementation compares specimen color with catalog color ranges. It is not a
/// trained Core ML classifier, so its scores are deliberately kept in the low-confidence band.
public final class CoreMLClassifierService: @unchecked Sendable {
    public static let shared = CoreMLClassifierService()
    
    public init() {}
    
    /// Executes Stage 1 on-device classification for a given specimen image.
    public func classify(image: UIImage) async throws -> Stage1Inference {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Downscale image for quick on-device analysis
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "CoreMLClassifierService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image data for CoreML input."])
        }
        
        // Compare the specimen's central color with catalog colors to build a shortlist.
        let visualProfile = analyzeVisualProfile(cgImage: cgImage)

        let ranked = rankMinerals(profile: visualProfile, minerals: MineralDatabase.shared.allMinerals)
        let topMatch = ranked.first ?? ("Clear Quartz", 0.35)
        
        let durationMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        
        return Stage1Inference(
            topMineralName: topMatch.key,
            score: topMatch.value,
            inferenceDurationMs: durationMs,
            allProbabilities: Dictionary(uniqueKeysWithValues: ranked.prefix(5).map { ($0.key, $0.value) })
        )
    }
    
    // MARK: - Internal Visual Feature Extraction
    private typealias VisualProfile = MineralColorScorer.Profile

    private func analyzeVisualProfile(cgImage: CGImage) -> VisualProfile {
        let width = 64
        let height = 64
        let cropSide = min(cgImage.width, cgImage.height)
        let cropInsetX = (cgImage.width - cropSide) / 2
        let cropInsetY = (cgImage.height - cropSide) / 2
        let cropRect = CGRect(x: CGFloat(cropInsetX), y: CGFloat(cropInsetY), width: CGFloat(cropSide), height: CGFloat(cropSide))
        let specimenImage = cgImage.cropping(to: cropRect) ?? cgImage
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return VisualProfile(hue: 0, saturation: 0, brightness: 0.5)
        }

        context.draw(specimenImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            return VisualProfile(hue: 0, saturation: 0, brightness: 0.5)
        }
        
        let ptr = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var sumR = 0.0
        var sumG = 0.0
        var sumB = 0.0
        let total = width * height
        
        for i in 0..<total {
            let r = Double(ptr[i * 4]) / 255.0
            let g = Double(ptr[i * 4 + 1]) / 255.0
            let b = Double(ptr[i * 4 + 2]) / 255.0
            sumR += r
            sumG += g
            sumB += b
        }
        
        let r = sumR / Double(total)
        let g = sumG / Double(total)
        let b = sumB / Double(total)
        
        let maxC = max(r, max(g, b))
        let minC = min(r, min(g, b))
        let delta = maxC - minC
        let saturation = maxC > 0 ? delta / maxC : 0
        let brightness = (r * 0.299) + (g * 0.587) + (b * 0.114)

        var hue = 0.0
        if delta > 0 {
            if maxC == r {
                hue = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxC == g {
                hue = 60 * (((b - r) / delta) + 2)
            } else {
                hue = 60 * (((r - g) / delta) + 4)
            }
            if hue < 0 { hue += 360 }
        }

        return VisualProfile(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func rankMinerals(profile: VisualProfile, minerals: [Mineral]) -> [(key: String, value: Double)] {
        MineralColorScorer.rank(
            profile: profile,
            minerals: minerals.map { (name: $0.name, colorRanges: $0.colorRange) }
        ).map {
            (key: $0.name, value: $0.score)
        }
    }
}
#endif

struct MineralColorScorer {
    struct Profile {
        let hue: Double
        let saturation: Double
        let brightness: Double
    }

    static func rank(
        profile: Profile,
        minerals: [(name: String, colorRanges: [String])]
    ) -> [(name: String, score: Double)] {
        let scored = minerals.map { mineral -> (name: String, score: Double) in
            let colorMatches = mineral.colorRanges.compactMap(colorSignature(for:))
            let similarity = colorMatches.map { colorSimilarity(profile, $0) }.max() ?? 0.35
            // Color alone is not enough to claim a reliable mineral identification.
            return (mineral.name, 0.25 + (similarity * 0.25))
        }

        return scored.sorted {
            if $0.score == $1.score {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.score > $1.score
        }
    }

    private static func colorSignature(for label: String) -> Profile? {
        let value = label.lowercased()
        let hueGroups: [(tokens: [String], hue: Double)] = [
            (["red", "ruby", "crimson", "scarlet", "carnelian", "brick"], 0),
            (["orange", "peach", "copper"], 28),
            (["yellow", "gold", "lemon", "citrine", "mustard", "amber"], 50),
            (["green", "emerald", "forest", "mint", "sage", "olive", "peridot"], 120),
            (["cyan", "turquoise", "teal", "aqua", "blue-green"], 180),
            (["blue", "navy", "ultramarine", "cobalt", "azure", "indigo"], 220),
            (["purple", "violet", "lilac", "lavender", "grape", "amethyst"], 275),
            (["pink", "rose", "blush", "morganite"], 335),
            (["brown", "tan", "whiskey", "earthy", "bronze"], 28)
        ]
        let matchedHues = hueGroups.compactMap { group in
            group.tokens.contains(where: value.contains) ? group.hue : nil
        }

        let isBlack = value.contains("black") || value.contains("pitch")
        let isWhite = value.contains("white") || value.contains("colorless") || value.contains("clear") || value.contains("icy")
        let isGray = value.contains("gray") || value.contains("grey") || value.contains("silver")
        guard !matchedHues.isEmpty || isBlack || isWhite || isGray else { return nil }

        let hue: Double
        if matchedHues.isEmpty {
            hue = 0
        } else {
            let radians = matchedHues.map { $0 * .pi / 180 }
            let averageSine = radians.map(sin).reduce(0, +) / Double(radians.count)
            let averageCosine = radians.map(cos).reduce(0, +) / Double(radians.count)
            hue = (atan2(averageSine, averageCosine) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        }
        let saturation = (isBlack || isWhite || isGray) && matchedHues.isEmpty ? 0.05 : 0.72
        let brightness: Double
        if isBlack {
            brightness = 0.08
        } else if isWhite {
            brightness = 0.92
        } else if value.contains("dark") || value.contains("deep") || value.contains("pitch") {
            brightness = 0.28
        } else if value.contains("pale") || value.contains("light") || value.contains("icy") {
            brightness = 0.78
        } else if matchedHues.contains(50) {
            brightness = 0.75
        } else {
            brightness = 0.52
        }

        return Profile(hue: hue, saturation: saturation, brightness: brightness)
    }

    private static func colorSimilarity(_ image: Profile, _ reference: Profile) -> Double {
        let rawHueDistance = abs(image.hue - reference.hue)
        let hueDistance = min(rawHueDistance, 360 - rawHueDistance) / 180
        let huePenalty = hueDistance * min(image.saturation, reference.saturation)
        let saturationPenalty = abs(image.saturation - reference.saturation)
        let brightnessPenalty = abs(image.brightness - reference.brightness)
        return max(0, 1 - (0.6 * huePenalty) - (0.2 * saturationPenalty) - (0.2 * brightnessPenalty))
    }
}
