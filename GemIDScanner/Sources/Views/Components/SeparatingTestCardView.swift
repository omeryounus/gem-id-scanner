import SwiftUI

/// Clean, actionable card displaying a physical separating test (Mohs scratch, streak, acid reaction, etc.).
public struct SeparatingTestCardView: View {
    public let index: Int
    public let testDescription: String
    
    public init(index: Int, testDescription: String) {
        self.index = index
        self.testDescription = testDescription
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("\(index)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.cyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(parseTestTitle(from: testDescription))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(parseTestBody(from: testDescription))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func parseTestTitle(from raw: String) -> String {
        let parts = raw.components(separatedBy: ":")
        if parts.count > 1 {
            return parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Physical Diagnostic Test"
    }
    
    private func parseTestBody(from raw: String) -> String {
        let parts = raw.components(separatedBy: ":")
        if parts.count > 1 {
            return parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return raw
    }
}
