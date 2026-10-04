import SwiftUI

/// Inline floating banner providing actionable camera adjustments when lighting or sharpness issues are detected.
public struct CaptureTipsBanner: View {
    public let warnings: [CameraQualityWarning]
    public var onDismiss: (() -> Void)?
    public var onEnableTorch: (() -> Void)?
    
    public init(
        warnings: [CameraQualityWarning],
        onDismiss: (() -> Void)? = nil,
        onEnableTorch: (() -> Void)? = nil
    ) {
        self.warnings = warnings
        self.onDismiss = onDismiss
        self.onEnableTorch = onEnableTorch
    }
    
    public var body: some View {
        if !warnings.isEmpty {
            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capture Quality Suggestion")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        
                        ForEach(warnings, id: \.self) { warning in
                            Text("• \(warning.rawValue)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    
                    Spacer()
                    
                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 18))
                        }
                    }
                }
                
                // Quick Action Bar
                if warnings.contains(.tooDark), let onEnableTorch = onEnableTorch {
                    Button(action: onEnableTorch) {
                        HStack(spacing: 6) {
                            Image(systemName: "flashlight.on.fill")
                            Text("Turn On Torch Flashlight")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.15, green: 0.14, blue: 0.12).opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
