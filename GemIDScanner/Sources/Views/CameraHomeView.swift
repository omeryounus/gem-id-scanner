import SwiftUI
import PhotosUI
import AVFoundation

/// Screen 1: Full-screen camera viewfinder with centering reticle, torch toggle,
/// gallery import, shutter trigger, and scan allowance monitoring.
public struct CameraHomeView: View {
    @StateObject private var camera = CameraService()
    @EnvironmentObject private var coordinator: IdentificationCoordinator
    @EnvironmentObject private var allowance: ScanAllowanceManager
    @EnvironmentObject private var storeKit: StoreKitService
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var activeImageToScan: UIImage?
    @State private var showPaywallSheet = false
    @State private var showAnalyzing = false
    @State private var showResult = false
    @State private var showBestGuesses = false
    @State private var activeResult: IdentificationResult?
    @State private var activeCapturedImage: UIImage?
    @State private var dismissalWarnings: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // 1. Live Camera Viewfinder
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
                    .onAppear {
                        Task {
                            await camera.checkPermissionsAndSetup()
                            camera.startSession()
                        }
                    }
                    .onDisappear {
                        camera.stopSession()
                    }
                
                // 2. Centering Reticle Overlay
                ReticleOverlayView(warningText: camera.currentQualityAssessment?.warnings.first?.rawValue)
                
                // 3. Top Controls HUD
                VStack {
                    HStack(alignment: .center) {
                        // Scan Allowance Badge / Pro Indicator
                        Button(action: {
                            if !storeKit.isProPurchased {
                                showPaywallSheet = true
                            }
                        }) {
                            HStack(spacing: 5) {
                                if storeKit.isProPurchased {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.amberGold)
                                    Text("PRO")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.cyan)
                                    Text("\(allowance.remainingDailyScans)/5 Daily IDs")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // Torch Flashlight Toggle
                        if camera.hasTorch {
                            Button(action: {
                                camera.toggleTorch()
                            }) {
                                Image(systemName: camera.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(camera.isTorchOn ? .yellow : .white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Capture Tips Banner (Screen 2)
                    if let assessment = camera.currentQualityAssessment, !assessment.warnings.isEmpty, !dismissalWarnings {
                        CaptureTipsBanner(
                            warnings: assessment.warnings,
                            onDismiss: { dismissalWarnings = true },
                            onEnableTorch: {
                                if !camera.isTorchOn {
                                    camera.toggleTorch()
                                }
                            }
                        )
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // 4. Bottom Capture Shutter Bar
                    HStack(alignment: .center, spacing: 32) {
                        // Gallery Photo Picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    processImageScan(image: image)
                                }
                            }
                        }
                        
                        // Shutter Trigger Button
                        Button(action: {
                            guard allowance.canPerformScan() else {
                                showPaywallSheet = true
                                return
                            }
                            
                            Task {
                                do {
                                    let image = try await camera.capturePhoto()
                                    processImageScan(image: image)
                                } catch {
                                    #if targetEnvironment(simulator)
                                    // Fallback for simulator: mock image scan
                                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
                                    let dummy = renderer.image { ctx in
                                        UIColor.systemPurple.setFill()
                                        ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
                                    }
                                    processImageScan(image: dummy)
                                    #else
                                    camera.errorMessage = "Failed to capture photo: \(error.localizedDescription)"
                                    #endif
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 78, height: 78)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 66, height: 66)
                            }
                        }
                        
                        // Quick Reference Encyclopedia shortcut
                        NavigationLink(destination: EncyclopediaCatalogView()) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .navigationDestination(isPresented: $showAnalyzing) {
                AnalyzingView(image: activeCapturedImage) { result in
                    allowance.recordScan()
                    self.activeResult = result
                    self.showAnalyzing = false
                    if result.confidenceBand == .bestGuesses {
                        self.showBestGuesses = true
                    } else {
                        self.showResult = true
                    }
                }
            }
            .navigationDestination(isPresented: $showResult) {
                if let res = activeResult {
                    ResultView(result: res, scannedImage: activeCapturedImage)
                }
            }
            .navigationDestination(isPresented: $showBestGuesses) {
                if let res = activeResult {
                    BestGuessesView(result: res, scannedImage: activeCapturedImage)
                }
            }
            .sheet(isPresented: $showPaywallSheet) {
                PaywallView()
            }
        }
    }
    
    private func processImageScan(image: UIImage) {
        guard allowance.canPerformScan() else {
            showPaywallSheet = true
            return
        }
        
        self.activeCapturedImage = image
        self.showAnalyzing = true
    }
}

/// AVFoundation camera preview UIViewRepresentable wrapper.
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

public class CameraPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
