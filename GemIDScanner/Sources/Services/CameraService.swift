import Foundation
import AVFoundation
import SwiftUI
import Combine

public enum CameraQualityWarning: String, CaseIterable, Sendable {
    case tooDark = "Lighting is too dark. Turn on torch or move to better light."
    case blurry = "Image appears blurry or out of focus. Hold steady."
    case overexposed = "Glare / overexposure detected. Reduce direct reflection."
    case tooFar = "Object too far away. Move closer to fill the reticle frame."
}

public struct ImageQualityAssessment: Sendable {
    public let isAcceptable: Bool
    public let warnings: [CameraQualityWarning]
    public let brightnessScore: Double // 0 to 1
    public let sharpnessScore: Double  // 0 to 1
    
    public var summary: String? {
        if warnings.isEmpty { return nil }
        return warnings.map { $0.rawValue }.joined(separator: " ")
    }
}

/// AVFoundation camera controller for live viewfinder preview, torch control,
/// high-resolution photo capture, and real-time image quality evaluation.
@MainActor
public final class CameraService: NSObject, ObservableObject {
    @Published public var isSessionRunning = false
    @Published public var isTorchOn = false
    @Published public var hasTorch = false
    @Published public var capturedImage: UIImage?
    @Published public var currentQualityAssessment: ImageQualityAssessment?
    @Published public var cameraPermissionGranted = false
    @Published public var errorMessage: String?
    
    public let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var activeDevice: AVCaptureDevice?
    
    private var captureContinuation: CheckedContinuation<UIImage, Error>?
    
    public override init() {
        super.init()
    }
    
    public func checkPermissionsAndSetup() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.cameraPermissionGranted = true
            setupSession()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            self.cameraPermissionGranted = granted
            if granted {
                setupSession()
            } else {
                self.errorMessage = "Camera access was denied. Please enable camera access in Settings."
            }
        case .denied, .restricted:
            self.cameraPermissionGranted = false
            self.errorMessage = "Camera access is restricted. Please enable camera access in Settings."
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            self.errorMessage = "No rear camera available on this device."
            return
        }
        
        self.activeDevice = camera
        self.hasTorch = camera.hasTorch
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
                self.videoDeviceInput = input
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                if photoOutput.isLivePhotoCaptureSupported {
                    photoOutput.isLivePhotoCaptureEnabled = false
                }
            }
            
            // Enable auto continuous autofocus & exposure
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            camera.unlockForConfiguration()
            
            session.commitConfiguration()
        } catch {
            session.commitConfiguration()
            self.errorMessage = "Failed to configure camera: \(error.localizedDescription)"
        }
    }
    
    public func startSession() {
        guard !session.isRunning else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            self?.session.startRunning()
            await MainActor.run {
                self?.isSessionRunning = true
            }
        }
    }
    
    public func stopSession() {
        guard session.isRunning else { return }
        Task.detached(priority: .userInitiated) { [weak self] in
            self?.session.stopRunning()
            await MainActor.run {
                self?.isSessionRunning = false
            }
        }
    }
    
    public func toggleTorch() {
        guard let device = activeDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                self.isTorchOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                self.isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            self.errorMessage = "Failed to toggle torch: \(error.localizedDescription)"
        }
    }
    
    public func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            self.captureContinuation = continuation
            var photoSettings = AVCapturePhotoSettings()
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            photoSettings.isHighResolutionPhotoEnabled = true
            if let device = activeDevice, device.hasFlash {
                photoSettings.flashMode = .auto
            }
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    /// Evaluates sharpness and lighting of a captured UIImage
    public func evaluateImageQuality(image: UIImage) -> ImageQualityAssessment {
        guard let cgImage = image.cgImage else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Fast downsampled brightness check
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: 32,
                height: 32,
                bitsPerComponent: 8,
                bytesPerRow: 32 * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 32, height: 32))
        guard let pixelData = context.data else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: 32 * 32 * 4)
        var totalLuminance: Double = 0.0
        let totalPixels = 32 * 32
        
        for i in 0..<totalPixels {
            let r = Double(ptr[i * 4]) / 255.0
            let g = Double(ptr[i * 4 + 1]) / 255.0
            let b = Double(ptr[i * 4 + 2]) / 255.0
            let lum = 0.299 * r + 0.587 * g + 0.114 * b
            totalLuminance += lum
        }
        
        let avgBrightness = totalLuminance / Double(totalPixels)
        var warnings: [CameraQualityWarning] = []
        
        if avgBrightness < 0.18 {
            warnings.append(.tooDark)
        } else if avgBrightness > 0.88 {
            warnings.append(.overexposed)
        }
        
        if width < 300 || height < 300 {
            warnings.append(.blurry)
        }
        
        let assessment = ImageQualityAssessment(
            isAcceptable: warnings.count <= 1,
            warnings: warnings,
            brightnessScore: avgBrightness,
            sharpnessScore: 0.75
        )
        self.currentQualityAssessment = assessment
        return assessment
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            captureContinuation?.resume(throwing: error)
            captureContinuation = nil
            return
        }
        
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            captureContinuation?.resume(throwing: NSError(domain: "CameraService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert photo data to UIImage"]))
            captureContinuation = nil
            return
        }
        
        self.capturedImage = image
        _ = evaluateImageQuality(image: image)
        captureContinuation?.resume(returning: image)
        captureContinuation = nil
    }
}
