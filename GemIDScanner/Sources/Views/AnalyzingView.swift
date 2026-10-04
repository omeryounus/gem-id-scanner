import SwiftUI

/// Screen 3: Animated radar scan view displaying two-stage neural & cloud progress steps.
public struct AnalyzingView: View {
    public let image: UIImage?
    public let onComplete: (IdentificationResult) -> Void
    
    @StateObject private var coordinator = IdentificationCoordinator.shared
    @State private var scanLaserOffset: CGFloat = -140
    @State private var radarRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    public init(image: UIImage?, onComplete: @escaping (IdentificationResult) -> Void) {
        self.image = image
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.07, blue: 0.10).ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 6) {
                    Text("IDENTIFYING SPECIMEN")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(2.0)
                        .foregroundColor(.cyan)
                    
                    Text("Two-Stage Dual Intelligence")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 24)
                
                // Animated Specimen Radar Frame
                ZStack {
                    // Specimen Thumbnail
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 240, height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 240, height: 240)
                    }
                    
                    // Radar Ring Waves
                    Circle()
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 230 * pulseScale, height: 230 * pulseScale)
                        .opacity(2.0 - Double(pulseScale))
                    
                    // Laser Scan Line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.8), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 236, height: 4)
                        .offset(y: scanLaserOffset)
                        .shadow(color: .cyan, radius: 8)
                }
                .frame(width: 260, height: 260)
                
                // Step-by-Step Progress Pipeline Indicator
                VStack(alignment: .leading, spacing: 14) {
                    StepRowView(
                        icon: "sparkle.magnifyingglass",
                        title: "1. Image Quality Assessment",
                        subtitle: "Lighting, focus, and reflection analysis",
                        isCurrent: coordinator.analysisStep == .assessingQuality,
                        isDone: coordinator.analysisStep != .idle && coordinator.analysisStep != .assessingQuality
                    )
                    
                    StepRowView(
                        icon: "cpu.fill",
                        title: "2. Stage 1: On-Device CoreML (<100ms)",
                        subtitle: "Local neural classification on 60-mineral catalog",
                        isCurrent: coordinator.analysisStep == .runningStage1OnDevice,
                        isDone: coordinator.analysisStep == .runningStage2CloudOpinion || coordinator.analysisStep == .mergingConfidence || coordinator.analysisStep == .complete
                    )
                    
                    StepRowView(
                        icon: "cloud.fill",
                        title: "3. Stage 2: Multimodal Gemini Opinion",
                        subtitle: "Crystal habit, luster, and lookalike analysis",
                        isCurrent: coordinator.analysisStep == .runningStage2CloudOpinion,
                        isDone: coordinator.analysisStep == .mergingConfidence || coordinator.analysisStep == .complete
                    )
                    
                    StepRowView(
                        icon: "checkmark.seal.fill",
                        title: "4. Confidence Merging & Rule-Out Tests",
                        subtitle: "Agreement capping (max 96%) & diagnostic tests",
                        isCurrent: coordinator.analysisStep == .mergingConfidence,
                        isDone: coordinator.analysisStep == .complete
                    )
                }
                .padding(.horizontal, 28)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Start scan animations
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scanLaserOffset = 110
            }
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                pulseScale = 1.35
            }
            
            // Execute identification pipeline
            Task {
                if let img = image {
                    if let result = try? await coordinator.identify(image: img) {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        onComplete(result)
                    }
                }
            }
        }
    }
}

private struct StepRowView: View {
    let icon: String
    let title: String
    let subtitle: String
    let isCurrent: Bool
    let isDone: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.emeraldGreen.opacity(0.2) : (isCurrent ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06)))
                    .frame(width: 32, height: 32)
                
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.emeraldGreen)
                } else if isCurrent {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? .white : (isDone ? .white.opacity(0.9) : .white.opacity(0.5)))
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
    }
}

extension Color {
    static let emeraldGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
}
