import SwiftUI

/// Reusable card displaying a lookalike mineral alongside diagnostic physical separating tests.
public struct LookalikeCardView: View {
    public let lookalike: Lookalike
    public var onSelectLookalike: (() -> Void)?
    
    public init(lookalike: Lookalike, onSelectLookalike: (() -> Void)? = nil) {
        self.lookalike = lookalike
        self.onSelectLookalike = onSelectLookalike
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOOKALIKE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.amberGold)
                    Text(lookalike.mineralName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                
                if let onSelect = onSelectLookalike {
                    Button(action: onSelect) {
                        Text("View Profile")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Visual Difference
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "eye.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 13))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visual Cue")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    Text(lookalike.visualDifference)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Separating Diagnostic Test
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.amberGold)
                    .font(.system(size: 13))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Separating Physical Test")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.amberGold)
                    Text(lookalike.separatingTest)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Hardness Comparison if available
            if let hardness = lookalike.hardnessComparison {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    Text(hardness)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

extension Color {
    static let amberGold = Color(red: 0.95, green: 0.68, blue: 0.18)
}
