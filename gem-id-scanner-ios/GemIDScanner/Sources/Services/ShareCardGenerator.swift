import Foundation
import SwiftUI
import UIKit

public enum ShareCardAspectRatio: String, CaseIterable, Identifiable, Sendable {
    case story9x16 = "9:16 (Stories/Reels)"
    case square1x1 = "1:1 (Square Feed)"
    
    public var id: String { rawValue }
    
    public var dimensions: CGSize {
        switch self {
        case .story9x16:
            return CGSize(width: 390, height: 693)
        case .square1x1:
            return CGSize(width: 420, height: 420)
        }
    }
}

/// Generates high-resolution branded share cards suitable for Instagram, Reels, TikTok, iMessage, and camera roll export.
@MainActor
public final class ShareCardGenerator {
    public static let shared = ShareCardGenerator()
    
    public init() {}
    
    /// Renders a share card view into a high-res UIImage using SwiftUI's ImageRenderer.
    public func renderShareCard(
        specimenImage: UIImage?,
        mineral: Mineral?,
        confidenceScore: Double,
        confidenceBand: ConfidenceBand,
        form: String? = nil,
        separatingTest: String? = nil,
        aspectRatio: ShareCardAspectRatio = .story9x16
    ) -> UIImage? {
        let cardView = ShareCardContentView(
            specimenImage: specimenImage,
            mineral: mineral,
            confidenceScore: confidenceScore,
            confidenceBand: confidenceBand,
            form: form,
            separatingTest: separatingTest ?? mineral?.ruleOutTests.first ?? mineral?.topLookalikes.first?.separatingTest,
            aspectRatio: aspectRatio
        )
        
        let size = aspectRatio.dimensions
        let renderer = ImageRenderer(content: cardView.frame(width: size.width, height: size.height))
        renderer.scale = 3.0 // 3x Retina resolution
        return renderer.uiImage
    }
}

/// The visual layout of the branded export share card (9:16 or 1:1).
public struct ShareCardContentView: View {
    public let specimenImage: UIImage?
    public let mineral: Mineral?
    public let confidenceScore: Double
    public let confidenceBand: ConfidenceBand
    public let form: String?
    public let separatingTest: String?
    public let aspectRatio: ShareCardAspectRatio
    
    public init(
        specimenImage: UIImage?,
        mineral: Mineral?,
        confidenceScore: Double,
        confidenceBand: ConfidenceBand,
        form: String? = nil,
        separatingTest: String? = nil,
        aspectRatio: ShareCardAspectRatio = .story9x16
    ) {
        self.specimenImage = specimenImage
        self.mineral = mineral
        self.confidenceScore = confidenceScore
        self.confidenceBand = confidenceBand
        self.form = form
        self.separatingTest = separatingTest
        self.aspectRatio = aspectRatio
    }
    
    public var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.12, green: 0.14, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if aspectRatio == .story9x16 {
                // 9:16 Vertical Story / Reel / Short Layout
                VStack(spacing: 14) {
                    // Header Branding
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                            Text("GEM ID SCANNER")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .tracking(2.0)
                                .foregroundColor(.white.opacity(0.95))
                        }
                        Spacer()
                        
                        // Confidence Pill
                        HStack(spacing: 4) {
                            Image(systemName: confidenceBand.iconName)
                            Text("\(Int(confidenceScore * 100))% \(confidenceBand.rawValue)")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(confidenceBand.themeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(confidenceBand.themeColor.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(confidenceBand.themeColor.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Specimen Photo Frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        
                        if let img = specimenImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Specimen Scan")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                    .frame(height: 320)
                    .padding(.horizontal, 20)
                    
                    // Identity & Key Specs
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(mineral?.name ?? "Identified Specimen")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            if let form = form {
                                Text(form.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.cyan.opacity(0.2))
                                    .foregroundColor(.cyan)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(mineral?.chemicalFormula ?? "Mineral Crystal")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.9))
                        
                        // Quick Specs Bar
                        HStack(spacing: 10) {
                            SpecimenQuickBadge(label: "MOHS", value: mineral?.mohsHardness ?? "7.0")
                            SpecimenQuickBadge(label: "LUSTER", value: mineral?.luster.components(separatedBy: " ").first ?? "Vitreous")
                            SpecimenQuickBadge(label: "SYSTEM", value: mineral?.crystalSystem.components(separatedBy: " ").first ?? "Trigonal")
                        }
                        .padding(.top, 4)
                        
                        // Separating Test Banner
                        if let test = separatingTest {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("DIAGNOSTIC SEPARATION TEST")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(.amberGold)
                                Text(test)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.amberGold.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 22)
                    
                    Spacer()
                    
                    // Footer
                    HStack {
                        Text("Two-Stage Dual Intelligence Identification")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                        Spacer()
                        Text("gemidscanner.app")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)
                }
            } else {
                // 1:1 Square Layout
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.cyan)
                            Text("GEM ID")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("\(Int(confidenceScore * 100))% • \(mineral?.name ?? "Mineral")")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(confidenceBand.themeColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    
                    HStack(spacing: 12) {
                        // Thumbnail
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.4))
                            if let img = specimenImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 170, height: 170)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .frame(width: 170, height: 170)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(mineral?.name ?? "Identified Specimen")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(mineral?.chemicalFormula ?? "SiO₂")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            HStack(spacing: 6) {
                                SpecimenQuickBadge(label: "MOHS", value: mineral?.mohsHardness ?? "7")
                                SpecimenQuickBadge(label: "LUSTER", value: mineral?.luster.components(separatedBy: " ").first ?? "Vitreous")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if let test = separatingTest {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.amberGold)
                            Text("Separating Test: \(test)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(2)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("Verified with Field Bench")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        Text("gemidscanner.app")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: aspectRatio.dimensions.width, height: aspectRatio.dimensions.height)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct SpecimenQuickBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
