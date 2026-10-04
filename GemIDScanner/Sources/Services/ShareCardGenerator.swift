import Foundation
import SwiftUI
import UIKit

/// Generates high-resolution branded share cards suitable for Instagram, iMessage, and camera roll export.
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
        form: String? = nil
    ) -> UIImage? {
        let cardView = ShareCardContentView(
            specimenImage: specimenImage,
            mineral: mineral,
            confidenceScore: confidenceScore,
            confidenceBand: confidenceBand,
            form: form
        )
        
        let renderer = ImageRenderer(content: cardView.frame(width: 390, height: 520))
        renderer.scale = 3.0 // 3x Retina resolution
        return renderer.uiImage
    }
}

/// The visual layout of the branded export share card.
public struct ShareCardContentView: View {
    public let specimenImage: UIImage?
    public let mineral: Mineral?
    public let confidenceScore: Double
    public let confidenceBand: ConfidenceBand
    public let form: String?
    
    public var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.12), Color(red: 0.12, green: 0.14, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                // Header Branding
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                    Text("GEM ID SCANNER")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .tracking(2.0)
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    
                    // Confidence Pill
                    HStack(spacing: 4) {
                        Image(systemName: confidenceBand.iconName)
                        Text("\(Int(confidenceScore * 100))%")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 12, weight: .heavy))
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
                .padding(.top, 20)
                
                // Specimen Photo Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    if let img = specimenImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
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
                .frame(height: 250)
                .padding(.horizontal, 20)
                
                // Identity & Key Specs
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(mineral?.name ?? "Identified Mineral")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        if let form = form {
                            Text(form.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(mineral?.chemicalFormula ?? "SiO₂")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.85))
                    
                    // Quick Specs Bar
                    HStack(spacing: 16) {
                        SpecimenQuickBadge(label: "MOHS", value: mineral?.mohsHardness ?? "7.0")
                        SpecimenQuickBadge(label: "LUSTER", value: mineral?.luster.components(separatedBy: " ").first ?? "Vitreous")
                        SpecimenQuickBadge(label: "SYSTEM", value: mineral?.crystalSystem.components(separatedBy: " ").first ?? "Trigonal")
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 4)
                
                // Footer
                HStack {
                    Text("Verified with Two-Stage Neural + Cloud Verification")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("gemidscanner.app")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 390, height: 520)
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
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
