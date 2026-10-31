import Foundation
import UIKit
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Verification basis provided by user to justify their correction.
public enum VerificationBasis: String, CaseIterable, Identifiable, Codable, Sendable {
    case dealerLabel = "dealer_label"
    case hardnessTest = "hardness_test"
    case expertNamed = "expert_named"
    case ownCollection = "own_collection"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .dealerLabel: return "Dealer / Lab Label"
        case .hardnessTest: return "Physical Test (Mohs/Streak)"
        case .expertNamed: return "Expert / Geologist Named"
        case .ownCollection: return "Personal Reference Collection"
        }
    }
    
    public var shortName: String {
        switch self {
        case .dealerLabel: return "Dealer Label"
        case .hardnessTest: return "Hardness Test"
        case .expertNamed: return "Expert Named"
        case .ownCollection: return "Own Collection"
        }
    }
    
    public var icon: String {
        switch self {
        case .dealerLabel: return "tag.fill"
        case .hardnessTest: return "shield.lefthalf.filled"
        case .expertNamed: return "person.badge.shield.checkmark.fill"
        case .ownCollection: return "archivebox.fill"
        }
    }
}

/// Specimen form options for user corrections.
public enum SpecimenFormOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case rough = "rough"
    case tumbled = "tumbled"
    case cut = "cut"
    case cabochon = "cabochon"
    case facet = "facet"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .rough: return "Rough / Natural"
        case .tumbled: return "Tumbled"
        case .cut: return "Cut"
        case .cabochon: return "Cabochon"
        case .facet: return "Faceted Gem"
        }
    }
}

/// A structured mineral correction item capturing ground-truth training feedback.
public struct MineralCorrectionItem: Identifiable, Codable, Sendable {
    public var id: UUID
    public let timestamp: Date
    public var photoData: Data?
    
    // Original model predictions (pred_1..pred_3, conf_1..conf_3)
    public let pred_1: String
    public let conf_1: Double
    public let pred_2: String?
    public let conf_2: Double?
    public let pred_3: String?
    public let conf_3: Double?
    
    // Model prompt version hash
    public let promptSHA256: String
    
    // User-selected ground truth
    public let userCorrectedMineral: String
    public let form: String
    public let verificationBasis: String
    public let userNotes: String
    
    // Telemetry and sync state
    public var isUploaded: Bool
    public var uploadTimestamp: Date?
    
    // Backward-compatibility accessors
    public var predictedMineral: String { pred_1 }
    public var confidenceAtPrediction: Double { conf_1 }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        photoData: Data? = nil,
        pred_1: String,
        conf_1: Double,
        pred_2: String? = nil,
        conf_2: Double? = nil,
        pred_3: String? = nil,
        conf_3: Double? = nil,
        promptSHA256: String = AppleVisionService.promptSHA256,
        userCorrectedMineral: String,
        form: String = "rough",
        verificationBasis: String = "dealer_label",
        userNotes: String = "",
        isUploaded: Bool = false,
        uploadTimestamp: Date? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.photoData = photoData
        self.pred_1 = pred_1
        self.conf_1 = conf_1
        self.pred_2 = pred_2
        self.conf_2 = conf_2
        self.pred_3 = pred_3
        self.conf_3 = conf_3
        self.promptSHA256 = promptSHA256
        self.userCorrectedMineral = userCorrectedMineral
        self.form = form
        self.verificationBasis = verificationBasis
        self.userNotes = userNotes
        self.isUploaded = isUploaded
        self.uploadTimestamp = uploadTimestamp
    }
}

/// Service managing offline queue of user corrections, disk persistence,
/// automated background cloud upload, and dataset packaging for model re-training.
@MainActor
public final class CorrectionFeedbackService: ObservableObject {
    public static let shared = CorrectionFeedbackService()
    
    private let queueDefaultsKey = "GemIDScanner_CorrectionQueue_v2"
    private let legacyQueueKey = "GemIDScanner_CorrectionQueue"
    private let webhookDefaultsKey = "GemIDScanner_CorrectionWebhookEndpoint"
    
    @Published public var queuedCorrections: [MineralCorrectionItem] = []
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncError: String?
    @Published public var lastSyncDate: Date?
    @Published public var modelImprovementOptIn: Bool = true {
        didSet {
            UserDefaults.standard.set(modelImprovementOptIn, forKey: "GemIDScanner_OptInModelImprovement")
        }
    }
    
    public var pendingCount: Int {
        queuedCorrections.filter { !$0.isUploaded }.count
    }
    
    public var uploadedCount: Int {
        queuedCorrections.filter { $0.isUploaded }.count
    }
    
    public var webhookEndpointURL: URL? {
        get {
            if let str = UserDefaults.standard.string(forKey: webhookDefaultsKey), let url = URL(string: str) {
                return url
            }
            return URL(string: "https://api.gemidscanner.com/v1/beta/corrections")
        }
        set {
            if let val = newValue {
                UserDefaults.standard.set(val.absoluteString, forKey: webhookDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: webhookDefaultsKey)
            }
        }
    }
    
    public init() {
        if UserDefaults.standard.object(forKey: "GemIDScanner_OptInModelImprovement") != nil {
            self.modelImprovementOptIn = UserDefaults.standard.bool(forKey: "GemIDScanner_OptInModelImprovement")
        } else {
            self.modelImprovementOptIn = false
        }
        loadQueue()
    }
    
    // MARK: - Submission API
    
    /// Submits a comprehensive user correction with predictions, prompt SHA-256, true label, form, and verification basis.
    public func submitCorrection(
        photoData: Data? = nil,
        pred_1: String,
        conf_1: Double,
        pred_2: String? = nil,
        conf_2: Double? = nil,
        pred_3: String? = nil,
        conf_3: Double? = nil,
        promptSHA256: String = AppleVisionService.promptSHA256,
        userCorrectedMineral: String,
        form: String = "rough",
        verificationBasis: String = "dealer_label",
        notes: String = ""
    ) {
        let item = MineralCorrectionItem(
            photoData: photoData,
            pred_1: pred_1,
            conf_1: conf_1,
            pred_2: pred_2,
            conf_2: conf_2,
            pred_3: pred_3,
            conf_3: conf_3,
            promptSHA256: promptSHA256,
            userCorrectedMineral: userCorrectedMineral,
            form: form,
            verificationBasis: verificationBasis,
            userNotes: notes,
            isUploaded: false
        )
        queuedCorrections.insert(item, at: 0)
        saveQueue()
        
        // Save image to disk if available
        if let data = photoData {
            saveImageToDisk(id: item.id, data: data)
        }
    }
    
    /// Convenience submission helper taking an IdentificationResult.
    public func submitCorrection(
        result: IdentificationResult,
        photoData: Data?,
        correctedMineral: String,
        form: String,
        verificationBasis: String,
        notes: String
    ) {
        let pred1 = result.topCandidate.mineralName
        let conf1 = result.mergedConfidence
        let pred2 = result.candidates.count > 1 ? result.candidates[1].mineralName : nil
        let conf2 = result.candidates.count > 1 ? result.candidates[1].score : nil
        let pred3 = result.candidates.count > 2 ? result.candidates[2].mineralName : nil
        let conf3 = result.candidates.count > 2 ? result.candidates[2].score : nil
        
        submitCorrection(
            photoData: photoData,
            pred_1: pred1,
            conf_1: conf1,
            pred_2: pred2,
            conf_2: conf2,
            pred_3: pred3,
            conf_3: conf3,
            promptSHA256: AppleVisionService.promptSHA256,
            userCorrectedMineral: correctedMineral,
            form: form,
            verificationBasis: verificationBasis,
            notes: notes
        )
    }
    
    /// Legacy compatibility submission method.
    public func submitCorrection(
        photoData: Data? = nil,
        predicted: String,
        corrected: String,
        notes: String,
        confidence: Double
    ) {
        submitCorrection(
            photoData: photoData,
            pred_1: predicted,
            conf_1: confidence,
            pred_2: nil,
            conf_2: nil,
            pred_3: nil,
            conf_3: nil,
            promptSHA256: AppleVisionService.promptSHA256,
            userCorrectedMineral: corrected,
            form: "rough",
            verificationBasis: "dealer_label",
            notes: notes
        )
    }
    
    // MARK: - Queue Management
    
    public func deleteCorrection(id: UUID) {
        queuedCorrections.removeAll { $0.id == id }
        deleteImageFromDisk(id: id)
        saveQueue()
    }
    
    public func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { queuedCorrections[$0].id }
        for id in idsToDelete {
            deleteImageFromDisk(id: id)
        }
        queuedCorrections.remove(atOffsets: offsets)
        saveQueue()
    }
    
    public func clearUploadedCorrections() {
        let uploaded = queuedCorrections.filter { $0.isUploaded }
        for item in uploaded {
            deleteImageFromDisk(id: item.id)
        }
        queuedCorrections.removeAll { $0.isUploaded }
        saveQueue()
    }
    
    public func clearAll() {
        for item in queuedCorrections {
            deleteImageFromDisk(id: item.id)
        }
        queuedCorrections.removeAll()
        saveQueue()
    }
    
    // MARK: - Automated Background & Manual Sync
    
    /// Synchronizes pending corrections to configured cloud/webhook endpoint.
    @discardableResult
    public func syncPendingCorrections(customEndpoint: URL? = nil) async -> (synced: Int, failed: Int) {
        guard !isSyncing else { return (0, 0) }
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }
        
        let pending = queuedCorrections.filter { !$0.isUploaded }
        guard !pending.isEmpty else { return (0, 0) }
        
        let endpoint = customEndpoint ?? webhookEndpointURL
        
        var syncedCount = 0
        var failedCount = 0
        
        if let targetURL = endpoint {
            // Attempt live network upload
            do {
                var request = URLRequest(url: targetURL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 10.0
                
                let payload = buildSyncPayload(items: pending)
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                    for i in 0..<queuedCorrections.count {
                        if !queuedCorrections[i].isUploaded {
                            queuedCorrections[i].isUploaded = true
                            queuedCorrections[i].uploadTimestamp = Date()
                            syncedCount += 1
                        }
                    }
                    self.lastSyncDate = Date()
                } else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? 500
                    failedCount = pending.count
                    self.lastSyncError = "Sync endpoint returned HTTP \(status)"
                }
            } catch {
                failedCount = pending.count
                self.lastSyncError = error.localizedDescription
            }
        } else {
            failedCount = pending.count
            self.lastSyncError = "No sync endpoint configured"
        }
        
        saveQueue()
        return (syncedCount, failedCount)
    }
    
    private func buildSyncPayload(items: [MineralCorrectionItem]) -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        let records: [[String: Any]] = items.map { item in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "timestamp": formatter.string(from: item.timestamp),
                "predicted_1": item.pred_1,
                "confidence_1": item.conf_1,
                "user_true_mineral": item.userCorrectedMineral,
                "specimen_form": item.form,
                "verification_basis": item.verificationBasis,
                "prompt_sha256": item.promptSHA256,
                "user_notes": item.userNotes
            ]
            if let p2 = item.pred_2, let c2 = item.conf_2 {
                dict["predicted_2"] = p2
                dict["confidence_2"] = c2
            }
            if let p3 = item.pred_3, let c3 = item.conf_3 {
                dict["predicted_3"] = p3
                dict["confidence_3"] = c3
            }
            if let photo = item.photoData ?? loadImageFromDisk(id: item.id) {
                dict["image_base64"] = photo.base64EncodedString()
            }
            return dict
        }
        
        return [
            "app": "GemIDScanner",
            "version": "1.0.0-beta",
            "batch_size": records.count,
            "export_timestamp": formatter.string(from: Date()),
            "corrections": records
        ]
    }
    
    // MARK: - Dataset Packaging & Zip Export
    
    /// Exports the entire corrections queue as a training dataset archive (JSON metadata + JPG images in a .zip file).
    public func exportCorrectionsDatasetZip() -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("GemID_Dataset_Export_\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let imagesDir = tempDir.appendingPathComponent("images", isDirectory: true)
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            
            var exportRecords: [[String: Any]] = []
            var zipEntries: [(name: String, data: Data)] = []
            let formatter = ISO8601DateFormatter()
            
            for item in queuedCorrections {
                let imgFileName = "correction_\(item.id.uuidString).jpg"
                var record: [String: Any] = [
                    "id": item.id.uuidString,
                    "timestamp": formatter.string(from: item.timestamp),
                    "image_file": "images/\(imgFileName)",
                    "predicted_1": item.pred_1,
                    "confidence_1": item.conf_1,
                    "user_true_mineral": item.userCorrectedMineral,
                    "specimen_form": item.form,
                    "verification_basis": item.verificationBasis,
                    "prompt_sha256": item.promptSHA256,
                    "user_notes": item.userNotes,
                    "is_uploaded": item.isUploaded
                ]
                if let p2 = item.pred_2, let c2 = item.conf_2 {
                    record["predicted_2"] = p2
                    record["confidence_2"] = c2
                }
                if let p3 = item.pred_3, let c3 = item.conf_3 {
                    record["predicted_3"] = p3
                    record["confidence_3"] = c3
                }
                exportRecords.append(record)
                
                // Write image data
                if let photo = item.photoData ?? loadImageFromDisk(id: item.id) {
                    let imgURL = imagesDir.appendingPathComponent(imgFileName)
                    try? photo.write(to: imgURL)
                    zipEntries.append((name: "images/\(imgFileName)", data: photo))
                }
            }
            
            let datasetDict: [String: Any] = [
                "schema_version": "2.0",
                "export_date": formatter.string(from: Date()),
                "total_samples": queuedCorrections.count,
                "prompt_sha256": AppleVisionService.promptSHA256,
                "corrections": exportRecords
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: datasetDict, options: [.prettyPrinted, .sortedKeys])
            let jsonURL = tempDir.appendingPathComponent("dataset.json")
            try jsonData.write(to: jsonURL)
            zipEntries.append((name: "dataset.json", data: jsonData))
            
            // Build pure-Swift ZIP archive
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateStr = dateFormatter.string(from: Date())
            let zipURL = fileManager.temporaryDirectory.appendingPathComponent("gem_id_corrections_dataset_\(dateStr).zip")
            
            if let zipData = PureSwiftZipWriter.createZip(entries: zipEntries) {
                try zipData.write(to: zipURL)
                return zipURL
            }
            
            return jsonURL
        } catch {
            return nil
        }
    }
    
    /// Exports metadata-only JSON string for quick inspection or sharing.
    public func exportCorrectionsJSON() -> URL? {
        let fileManager = FileManager.default
        let formatter = ISO8601DateFormatter()
        let records = queuedCorrections.map { item -> [String: Any] in
            var dict: [String: Any] = [
                "id": item.id.uuidString,
                "timestamp": formatter.string(from: item.timestamp),
                "predicted_1": item.pred_1,
                "confidence_1": item.conf_1,
                "user_true_mineral": item.userCorrectedMineral,
                "specimen_form": item.form,
                "verification_basis": item.verificationBasis,
                "prompt_sha256": item.promptSHA256,
                "user_notes": item.userNotes,
                "is_uploaded": item.isUploaded
            ]
            if let p2 = item.pred_2, let c2 = item.conf_2 {
                dict["predicted_2"] = p2
                dict["confidence_2"] = c2
            }
            if let p3 = item.pred_3, let c3 = item.conf_3 {
                dict["predicted_3"] = p3
                dict["confidence_3"] = c3
            }
            return dict
        }
        
        let container: [String: Any] = [
            "export_date": formatter.string(from: Date()),
            "total_count": records.count,
            "corrections": records
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: container, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }
        
        let targetURL = fileManager.temporaryDirectory.appendingPathComponent("corrections_metadata.json")
        try? data.write(to: targetURL)
        return targetURL
    }
    
    // MARK: - Disk Storage Helpers
    
    private var correctionsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("GemIDScanner/Corrections", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var imagesDirectory: URL {
        let dir = correctionsDirectory.appendingPathComponent("images", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private func saveImageToDisk(id: UUID, data: Data) {
        let fileURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        try? data.write(to: fileURL)
    }
    
    public func loadImageFromDisk(id: UUID) -> Data? {
        let fileURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        return try? Data(contentsOf: fileURL)
    }
    
    private func deleteImageFromDisk(id: UUID) {
        let fileURL = imagesDirectory.appendingPathComponent("\(id.uuidString).jpg")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func saveQueue() {
        let jsonFileURL = correctionsDirectory.appendingPathComponent("corrections.json")
        let metadataOnly = queuedCorrections.map { item -> MineralCorrectionItem in
            var copy = item
            copy.photoData = nil
            return copy
        }
        if let data = try? JSONEncoder().encode(metadataOnly) {
            try? data.write(to: jsonFileURL)
        }
        UserDefaults.standard.removeObject(forKey: queueDefaultsKey)
    }
    
    private func loadQueue() {
        let jsonFileURL = correctionsDirectory.appendingPathComponent("corrections.json")
        if let fileData = try? Data(contentsOf: jsonFileURL),
           let list = try? JSONDecoder().decode([MineralCorrectionItem].self, from: fileData) {
            self.queuedCorrections = list.map { item in
                var copy = item
                copy.photoData = loadImageFromDisk(id: item.id)
                return copy
            }
            return
        }
        
        // Fallback to UserDefaults
        if let data = UserDefaults.standard.data(forKey: queueDefaultsKey),
           let list = try? JSONDecoder().decode([MineralCorrectionItem].self, from: data) {
            self.queuedCorrections = list
            saveQueue()
            return
        }
        
        // Legacy queue migration
        if let legacyData = UserDefaults.standard.data(forKey: legacyQueueKey),
           let legacyList = try? JSONDecoder().decode([LegacyCorrectionItem].self, from: legacyData) {
            self.queuedCorrections = legacyList.map { legacy in
                MineralCorrectionItem(
                    id: legacy.id,
                    timestamp: legacy.timestamp,
                    photoData: legacy.photoData,
                    pred_1: legacy.predictedMineral,
                    conf_1: legacy.confidenceAtPrediction,
                    promptSHA256: AppleVisionService.promptSHA256,
                    userCorrectedMineral: legacy.userCorrectedMineral,
                    form: "rough",
                    verificationBasis: "dealer_label",
                    userNotes: legacy.userNotes,
                    isUploaded: legacy.isUploaded
                )
            }
            saveQueue()
        }
    }
}

// MARK: - Legacy Data Model Support
private struct LegacyCorrectionItem: Codable {
    let id: UUID
    let timestamp: Date
    let photoData: Data?
    let predictedMineral: String
    let userCorrectedMineral: String
    let userNotes: String
    let confidenceAtPrediction: Double
    let isUploaded: Bool
}

// MARK: - Pure Swift ZIP Format Writer (Store Compression)
public enum PureSwiftZipWriter {
    public static func createZip(entries: [(name: String, data: Data)]) -> Data? {
        guard entries.count <= UInt16.max else { return nil }
        var zipData = Data()
        var centralDirectory = Data()
        var fileOffsets: [UInt32] = []
        
        for entry in entries {
            guard zipData.count <= UInt32.max, entry.data.count <= UInt32.max else { return nil }
            let offset = UInt32(zipData.count)
            fileOffsets.append(offset)
            
            let nameBytes = Array(entry.name.utf8)
            guard nameBytes.count <= UInt16.max else { return nil }
            let nameLength = UInt16(nameBytes.count)
            let dataLength = UInt32(entry.data.count)
            let crc = crc32(entry.data)
            
            // Local file header (30 bytes + name)
            var header = Data()
            header.append(contentsOf: [0x50, 0x4B, 0x03, 0x04]) // Signature 0x04034b50
            header.append(contentsOf: UInt16(20).littleEndianBytes) // Min version (2.0)
            header.append(contentsOf: UInt16(0).littleEndianBytes)  // Flags
            header.append(contentsOf: UInt16(0).littleEndianBytes)  // Compression method (0 = Store)
            header.append(contentsOf: UInt16(0).littleEndianBytes)  // Mod time
            header.append(contentsOf: UInt16(0).littleEndianBytes)  // Mod date
            header.append(contentsOf: crc.littleEndianBytes)        // CRC-32
            header.append(contentsOf: dataLength.littleEndianBytes) // Compressed size
            header.append(contentsOf: dataLength.littleEndianBytes) // Uncompressed size
            header.append(contentsOf: nameLength.littleEndianBytes) // File name length
            header.append(contentsOf: UInt16(0).littleEndianBytes)  // Extra field length
            header.append(contentsOf: nameBytes)
            
            zipData.append(header)
            zipData.append(entry.data)
            
            // Central directory record for this entry (46 bytes + name)
            var cdRecord = Data()
            cdRecord.append(contentsOf: [0x50, 0x4B, 0x01, 0x02]) // Signature 0x02014b50
            cdRecord.append(contentsOf: UInt16(20).littleEndianBytes) // Version made by
            cdRecord.append(contentsOf: UInt16(20).littleEndianBytes) // Version needed
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Flags
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Compression (0 = Store)
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Mod time
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Mod date
            cdRecord.append(contentsOf: crc.littleEndianBytes)        // CRC-32
            cdRecord.append(contentsOf: dataLength.littleEndianBytes) // Compressed size
            cdRecord.append(contentsOf: dataLength.littleEndianBytes) // Uncompressed size
            cdRecord.append(contentsOf: nameLength.littleEndianBytes) // File name length
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Extra length
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Comment length
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Disk start
            cdRecord.append(contentsOf: UInt16(0).littleEndianBytes)  // Internal file attrs
            cdRecord.append(contentsOf: UInt32(0).littleEndianBytes)  // External file attrs
            cdRecord.append(contentsOf: offset.littleEndianBytes)     // Relative offset of local header
            cdRecord.append(contentsOf: nameBytes)
            
            centralDirectory.append(cdRecord)
        }
        
        let cdOffset = UInt32(zipData.count)
        let cdSize = UInt32(centralDirectory.count)
        let count = UInt16(entries.count)
        
        zipData.append(centralDirectory)
        
        // End of central directory record (22 bytes)
        var eocd = Data()
        eocd.append(contentsOf: [0x50, 0x4B, 0x05, 0x06]) // Signature 0x06054b50
        eocd.append(contentsOf: UInt16(0).littleEndianBytes)  // Disk number
        eocd.append(contentsOf: UInt16(0).littleEndianBytes)  // Start disk
        eocd.append(contentsOf: count.littleEndianBytes)       // Entries on this disk
        eocd.append(contentsOf: count.littleEndianBytes)       // Total entries
        eocd.append(contentsOf: cdSize.littleEndianBytes)      // Central directory size
        eocd.append(contentsOf: cdOffset.littleEndianBytes)    // Central directory offset
        eocd.append(contentsOf: UInt16(0).littleEndianBytes)  // Comment length
        
        zipData.append(eocd)
        return zipData
    }
    
    private static func crc32(_ data: Data) -> UInt32 {
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var c = UInt32(i)
            for _ in 0..<8 {
                if (c & 1) != 0 {
                    c = 0xEDB88320 ^ (c >> 1)
                } else {
                    c = c >> 1
                }
            }
            table[i] = c
        }
        
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension FixedWidthInteger {
    var littleEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.littleEndian) { Array($0) }
    }
}
