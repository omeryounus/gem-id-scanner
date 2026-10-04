import SwiftUI

/// Screen: Offline Mineral Correction Queue Management
///
/// Displays user-submitted misidentification corrections, offline telemetry storage,
/// specimen form & verification basis metadata, sync status with remote training dataset,
/// and dataset export controls.
public struct CorrectionQueueView: View {
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showClearConfirmation = false
    @State private var syncToastMessage: String?
    @State private var exportZipURL: URL?
    @State private var showExportSheet = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea()
            
            if feedbackService.queuedCorrections.isEmpty {
                emptyQueueView
            } else {
                List {
                    // Header Educational Banner
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "cpu.fill")
                                    .foregroundColor(.cyan)
                                Text("AI CONTINUOUS LEARNING")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            
                            Text("Your corrections train our mineral recognition models to resolve difficult crystal habits, pseudomorphs, and lookalike varieties.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(3)
                            
                            HStack(spacing: 12) {
                                Label("\(feedbackService.pendingCount) Pending", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(feedbackService.pendingCount > 0 ? .amberGold : .emeraldGreen)
                                
                                Label("\(feedbackService.uploadedCount) Synced", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.emeraldGreen)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.04))
                    }
                    
                    // Queue Action Controls (Sync Now, Export Dataset, Clear Synced)
                    Section {
                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                Button(action: handleSync) {
                                    HStack {
                                        if feedbackService.isSyncing {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.clockwise.icloud.fill")
                                            Text("Sync Pending")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.cyan.opacity(0.25))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.cyan.opacity(0.6), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(feedbackService.isSyncing || feedbackService.pendingCount == 0)
                                .opacity(feedbackService.pendingCount == 0 ? 0.5 : 1.0)
                                
                                Button(action: handleExportDataset) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up.fill")
                                        Text("Export Zip")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.system(size: 13))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.amberGold)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if feedbackService.uploadedCount > 0 {
                                Button(action: {
                                    feedbackService.clearUploadedCorrections()
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Clear Synced Corrections (\(feedbackService.uploadedCount))")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    
                    // Queued Items
                    Section("Queued Corrections (\(feedbackService.queuedCorrections.count))") {
                        ForEach(feedbackService.queuedCorrections) { item in
                            CorrectionItemRow(item: item)
                                .listRowBackground(Color.white.opacity(0.04))
                        }
                        .onDelete { indexSet in
                            feedbackService.delete(at: indexSet)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            
            // Sync Notification Toast
            if let toast = syncToastMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.emeraldGreen)
                        Text(toast)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.emeraldGreen.opacity(0.4), lineWidth: 1))
                    .shadow(radius: 10)
                    .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Offline Correction Queue")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            if let url = exportZipURL {
                ShareActivitySheet(activityItems: [url])
            }
        }
        .toolbar {
            if !feedbackService.queuedCorrections.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showClearConfirmation = true }) {
                        Text("Clear All")
                            .font(.system(size: 14))
                            .foregroundColor(.coralRed)
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear Entire Correction Queue?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Corrections", role: .destructive) {
                feedbackService.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all pending and synced offline mineral corrections from local storage.")
        }
    }
    
    private var emptyQueueView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 88, height: 88)
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text("Queue is Clean")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("When you correct an ambiguous scan or provide expert feedback on misidentified minerals, submissions are safely queued here until synchronized.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private func handleSync() {
        Task {
            let result = await feedbackService.syncPendingCorrections()
            withAnimation {
                syncToastMessage = "Successfully synced \(result.synced) correction\(result.synced == 1 ? "" : "s")!"
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                syncToastMessage = nil
            }
        }
    }
    
    private func handleExportDataset() {
        if let zipURL = feedbackService.exportCorrectionsDatasetZip() {
            self.exportZipURL = zipURL
            self.showExportSheet = true
        }
    }
}

// MARK: - Row Subview

private struct CorrectionItemRow: View {
    let item: MineralCorrectionItem
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Status Badge + Date
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.isUploaded ? Color.emeraldGreen : Color.amberGold)
                        .frame(width: 7, height: 7)
                    Text(item.isUploaded ? "SYNCED" : "PENDING SYNC")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(item.isUploaded ? .emeraldGreen : .amberGold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((item.isUploaded ? Color.emeraldGreen : Color.amberGold).opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                Text(item.timestamp, style: .date)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Specimen Image & Name Contrast
            HStack(spacing: 12) {
                let photoData = item.photoData ?? feedbackService.loadImageFromDisk(id: item.id)
                if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Ground Truth Label
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.emeraldGreen)
                        Text(item.userCorrectedMineral)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // Original Prediction
                    HStack(spacing: 4) {
                        Text("Model said:")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                        Text(item.pred_1)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.coralRed.opacity(0.9))
                            .strikethrough()
                        Text("(\(Int(item.conf_1 * 100))%)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
            }
            
            // Metadata Tags: Form, Verification Basis, Prompt SHA
            HStack(spacing: 6) {
                // Form Tag
                Text(item.form.capitalized)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())
                
                // Verification Basis Tag
                let basis = VerificationBasis(rawValue: item.verificationBasis)
                HStack(spacing: 4) {
                    if let icon = basis?.icon {
                        Image(systemName: icon)
                            .font(.system(size: 9))
                    }
                    Text(basis?.shortName ?? item.verificationBasis)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.amberGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.amberGold.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                // Prompt Version Hash Tag
                Text("SHA: \(String(item.promptSHA256.prefix(6)))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
            
            // Optional User Notes
            if !item.userNotes.isEmpty {
                Text(item.userNotes)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 6)
    }
}
