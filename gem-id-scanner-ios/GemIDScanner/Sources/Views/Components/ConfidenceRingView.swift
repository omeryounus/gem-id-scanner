import SwiftUI

/// Animated circular confidence gauge with color coding based on ConfidenceBand.
public struct ConfidenceRingView: View {
    public let score: Double
    public let band: ConfidenceBand
    public var lineWidth: CGFloat = 10
    public var size: CGFloat = 110
    
    @State private var animatedProgress: Double = 0.0
    
    public init(score: Double, band: ConfidenceBand, lineWidth: CGFloat = 10, size: CGFloat = 110) {
        self.score = min(max(score, 0.0), 1.0)
        self.band = band
        self.lineWidth = lineWidth
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(band.themeColor.opacity(0.18), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(animatedProgress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [band.themeColor.opacity(0.6), band.themeColor]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.spring(response: 1.0, dampingFraction: 0.75), value: animatedProgress)
            
            // Center score label
            VStack(spacing: 2) {
                Text("\(Int(score * 100))%")
                    .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text(band.rawValue.uppercased())
                    .font(.system(size: size * 0.10, weight: .bold, design: .monospaced))
                    .foregroundColor(band.themeColor)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.animatedProgress = self.score
            }
        }
    }
}
