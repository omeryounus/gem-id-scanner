import SwiftUI
import SwiftData

/// Screen 5: Multi-candidate disambiguation view for Best Guesses (<55%) and Likely matches (55-84%).
/// Displays the top 3 possibilities alongside physical separating tests, 'Rule this in' guidance,
/// and a 'None of these' correction trigger.
public struct BestGuessesView: View {
    public let result: IdentificationResult
    public let scannedImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var allowance: ScanAllowanceManager
    
    @Query private var existingSpecimens: [SpecimenRecord]
    
    @State private var selectedCandidateIndex: Int = 0
    @State private var showCorrectionSheet = false
    @State private var showDetailSheet = false
    @State private var showPaywallSheet = false
    @State private var inspectedMineral: Mineral?
    @State private var correctionMineralName = ""
    @State private var correctionNotes = ""
    @State private var isSaved = false
    
    public init(result: IdentificationResult, scannedImage: UIImage?) {
        self.result = result
        self.scannedImage = scannedImage
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Warning Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "questionmark.diamond.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.coralRed)
                        Text("VISUAL AMBIGUITY DETECTED")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(.coralRed)
                    }
                    
                    Text("Best Guesses")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Multiple minerals share this color and crystal habit (<55% confidence). Use the physical diagnostic tests below to confirm the exact specimen.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if let summary = result.stage2Prediction?.engineSummary {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 12)
                
                // Top Candidates List (Top 3)
                VStack(spacing: 14) {
                    ForEach(Array(result.candidates.prefix(3).enumerated()), id: \.offset) { index, candidate in
                        CandidateOptionCard(
                            index: index + 1,
                            candidate: candidate,
                            isSelected: selectedCandidateIndex == index,
                            onSelect: { selectedCandidateIndex = index },
                            onInspect: {
                                self.inspectedMineral = MineralDatabase.shared.find(byName: candidate.mineralName)
                                self.showDetailSheet = true
                            }
                        )
                    }
                }
                
                // Active Separating Tests Card for Selected Candidate
                let currentCandidate = result.candidates[min(selectedCandidateIndex, result.candidates.count - 1)]
                let currentMineral = MineralDatabase.shared.find(byName: currentCandidate.mineralName)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.cyan)
                        Text("DIAGNOSTIC TESTS FOR \(currentCandidate.mineralName.uppercased())")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    if let tests = currentMineral?.ruleOutTests {
                        ForEach(Array(tests.enumerated()), id: \.offset) { idx, testStr in
                            SeparatingTestCardView(index: idx + 1, testDescription: testStr)
                        }
                    }
                }
                .padding(.top, 8)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Confirm Selected Candidate
                    Button(action: saveSelectedCandidate) {
                        HStack {
                            Image(systemName: isSaved ? "checkmark" : "hand.thumbsup.fill")
                            Text(isSaved ? "Saved to Collection" : "Confirm as \(currentCandidate.mineralName)")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSaved ? Color.emeraldGreen : Color.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSaved)
                    
                    // 'None of these match? Send Correction' Action
                    Button(action: { showCorrectionSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.amberGold)
                            Text("None of these match? Send Correction")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.amberGold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.amberGold.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 12)
            }
            .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle("Best Guesses")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetailSheet) {
            if let min = inspectedMineral {
                NavigationStack {
                    MineralDetailView(mineral: min)
                }
            }
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallView()
        }
        .sheet(isPresented: $showCorrectionSheet) {
            CorrectionSheetView(
                result: result,
                scannedImage: scannedImage
            )
        }
    }
    
    private func saveSelectedCandidate() {
        guard allowance.canAddToCollection(currentCollectionCount: existingSpecimens.count) else {
            showPaywallSheet = true
            return
        }
        
        let candidate = result.candidates[min(selectedCandidateIndex, result.candidates.count - 1)]
        let photoData = scannedImage?.jpegData(compressionQuality: 0.8)
        let record = SpecimenRecord(
            photoData: photoData,
            mineralName: candidate.mineralName,
            confidence: candidate.score,
            confidenceBand: candidate.confidenceBand,
            notes: "Confirmed manually from Best Guesses list.",
            form: "Rough",
            isFavorite: false,
            userConfirmed: true
        )
        modelContext.insert(record)
        do {
            try modelContext.save()
            withAnimation {
                isSaved = true
            }
        } catch {
            print("Failed to save selected candidate: \(error.localizedDescription)")
        }
    }
}

private struct CandidateOptionCard: View {
    let index: Int
    let candidate: CandidateItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onInspect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.cyan : Color.white.opacity(0.1))
                            .frame(width: 26, height: 26)
                        Text("\(index)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isSelected ? .black : .white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.mineralName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if let mineral = MineralDatabase.shared.find(byName: candidate.mineralName) {
                            Text("Mohs \(mineral.mohsHardness) • \(mineral.crystalSystem.components(separatedBy: " ").first ?? "")")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Match Score Badge
                    Text("\(Int(candidate.score * 100))%")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(candidate.confidenceBand.themeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(candidate.confidenceBand.themeColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                if let ruleIn = candidate.ruleInAction {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                        Text("How to confirm: \(ruleIn)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                HStack {
                    Spacer()
                    Button(action: onInspect) {
                        Text("Encyclopedia Profile →")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? Color.cyan.opacity(0.12) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension Color {
    static let coralRed = Color(red: 0.92, green: 0.35, blue: 0.35)
}
