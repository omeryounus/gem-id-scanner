import SwiftUI

/// Centering reticle HUD overlaid over the live camera viewfinder.
public struct ReticleOverlayView: View {
    @State private var isPulsing = false
    public var warningText: String?
    
    public init(warningText: String? = nil) {
        self.warningText = warningText
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let frameSize = min(geometry.size.width * 0.72, 280.0)
            
            ZStack {
                // Dimmed surrounding vignette
                Color.black.opacity(0.35)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(width: frameSize, height: frameSize)
                                    .blendMode(.destinationOut)
                            )
                    )
                
                // Centering Target Box
                ZStack {
                    // Corner Reticle Brackets
                    ReticleCornersShape(cornerRadius: 24, length: 32)
                        .stroke(
                            warningText != nil ? Color.yellow : Color.cyan,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: frameSize, height: frameSize)
                        .shadow(color: (warningText != nil ? Color.yellow : Color.cyan).opacity(0.5), radius: isPulsing ? 8 : 3)
                    
                    // Center crosshair dot
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 6, height: 6)
                }
                
                // Alignment Tip
                VStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("Center rock or mineral specimen in frame")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 4)
                        
                        Text("Keep 4-8 inches away for crisp focus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.8), radius: 4)
                    }
                    .padding(.bottom, geometry.size.height * 0.22)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}

private struct ReticleCornersShape: Shape {
    let cornerRadius: CGFloat
    let length: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let len = length
        
        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))
        
        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
        
        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
        
        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))
        
        return path
    }
}
