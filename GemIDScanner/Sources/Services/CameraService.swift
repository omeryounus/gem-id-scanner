import Foundation
import AVFoundation
import SwiftUI
import Combine

public enum CameraQualityWarning: String, CaseIterable, Sendable {
    case tooDark = "Lighting is too dark. Turn on torch or move to better light."
    case blurry = "Specimen is blurry. Hold still to focus."
    case overexposed = "Too bright - reduce glare"
    case tooFar = "Move closer - fill the frame"
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
    
    /// Evaluates sharpness (variance of Laplacian) and lighting/glare of a captured UIImage
    public func evaluateImageQuality(image: UIImage) -> ImageQualityAssessment {
        let assessment = Self.evaluateImageQuality(image: image)
        self.currentQualityAssessment = assessment
        if UserDefaults.standard.bool(forKey: "GemIDScanner_AutoTorch") && assessment.brightnessScore < 0.20 && !isTorchOn {
            toggleTorch()
        }
        return assessment
    }
    
    public nonisolated static func evaluateImageQuality(image: UIImage) -> ImageQualityAssessment {
        guard let cgImage = image.cgImage else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        let width = 64
        let height = 64
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else {
            return ImageQualityAssessment(isAcceptable: true, warnings: [], brightnessScore: 0.5, sharpnessScore: 0.5)
        }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height)
        var totalLuminance: Double = 0.0
        var overexposedPixels = 0
        let totalPixels = width * height
        
        var grayGrid = [Double](repeating: 0.0, count: totalPixels)
        for i in 0..<totalPixels {
            let val = Double(ptr[i]) / 255.0
            grayGrid[i] = val
            totalLuminance += val
            if val > 0.92 {
                overexposedPixels += 1
            }
        }
        
        let avgBrightness = totalLuminance / Double(totalPixels)
        let overexposedRatio = Double(overexposedPixels) / Double(totalPixels)
        
        // Variance of Laplacian computation on 64x64 grayscale grid
        var laplacianValues: [Double] = []
        laplacianValues.reserveCapacity((width - 2) * (height - 2))
        
        var laplacianSum: Double = 0.0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let center = grayGrid[y * width + x]
                let top = grayGrid[(y - 1) * width + x]
                let bottom = grayGrid[(y + 1) * width + x]
                let left = grayGrid[y * width + (x - 1)]
                let right = grayGrid[y * width + (x + 1)]
                
                // Discrete 2D Laplacian operator: [0, 1, 0; 1, -4, 1; 0, 1, 0]
                let lap = (top + bottom + left + right) - (4.0 * center)
                laplacianValues.append(lap)
                laplacianSum += lap
            }
        }
        
        let count = Double(laplacianValues.count)
        let laplacianMean = count > 0 ? (laplacianSum / count) : 0.0
        var varianceSum: Double = 0.0
        for val in laplacianValues {
            let diff = val - laplacianMean
            varianceSum += (diff * diff)
        }
        let laplacianVariance = count > 0 ? (varianceSum / count) : 0.0
        let sharpnessScore = min(laplacianVariance * 120.0, 1.0)
        
        var warnings: [CameraQualityWarning] = []
        
        // Quality checks
        if avgBrightness < 0.16 {
            warnings.append(.tooDark)
        } else if avgBrightness > 0.82 || overexposedRatio > 0.22 {
            warnings.append(.overexposed)
        }
        
        // Low variance of Laplacian indicates blur or object too far
        if laplacianVariance < 0.0018 || cgImage.width < 300 || cgImage.height < 300 {
            warnings.append(.blurry)
        }
        
        return ImageQualityAssessment(
            isAcceptable: warnings.isEmpty,
            warnings: warnings,
            brightnessScore: avgBrightness,
            sharpnessScore: sharpnessScore
        )
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let resultImage: UIImage?
        let captureError: Error?
        
        if let error = error {
            captureError = error
            resultImage = nil
        } else if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            resultImage = image
            captureError = nil
        } else {
            resultImage = nil
            captureError = NSError(domain: "CameraService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert photo data to UIImage"])
        }
        
        Task { @MainActor in
            if let error = captureError {
                self.captureContinuation?.resume(throwing: error)
                self.captureContinuation = nil
            } else if let image = resultImage {
                self.capturedImage = image
                _ = self.evaluateImageQuality(image: image)
                self.captureContinuation?.resume(returning: image)
                self.captureContinuation = nil
            }
        }
    }
}
