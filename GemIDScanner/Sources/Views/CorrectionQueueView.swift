import SwiftUI

/// Screen: Offline Mineral Correction Queue Management
///
/// Displays user-submitted misidentification corrections, offline telemetry storage,
/// sync status with remote training dataset, and queue clearing controls.
public struct CorrectionQueueView: View {
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showClearConfirmation = false
    @State private var syncToastMessage: String?
    
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
                                
                                Label("\(feedbackService.queuedCorrections.count - feedbackService.pendingCount) Synced", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.emeraldGreen)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.04))
                    }
                    
                    // Queue Action Controls
                    Section {
                        HStack(spacing: 12) {
                            Button(action: {
                                handleSync()
                            }) {
                                HStack {
                                    if feedbackService.isSyncing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.clockwise.icloud.fill")
                                        Text("Sync Pending Queue")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .font(.system(size: 14))
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
                            
                            Button(action: {
                                feedbackService.clearUploadedCorrections()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear Synced")
                                        .fontWeight(.semibold)
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(PlainButtonStyle())
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
            let count = await feedbackService.syncPendingCorrections()
            withAnimation {
                syncToastMessage = "Successfully synced \(count) correction\(count == 1 ? "" : "s")!"
            }
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation {
                syncToastMessage = nil
            }
        }
    }
}

// MARK: - Row Subview

private struct CorrectionItemRow: View {
    let item: MineralCorrectionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                // Status Badge
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
            
            // Predicted -> Corrected Visual Diff
            HStack(spacing: 10) {
                if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Predicted")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(item.predictedMineral)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.coralRed)
                        .strikethrough()
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("User Correction")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                    Text(item.userCorrectedMineral)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.emeraldGreen)
                }
                
                Spacer()
                
                Text("\(Int(item.confidenceAtPrediction * 100))% conf")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if !item.userNotes.isEmpty {
                Text(item.userNotes)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
    }
}
