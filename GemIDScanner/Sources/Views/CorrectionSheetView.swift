import SwiftUI

/// Reusable modal sheet enabling beta testers to submit verified ground-truth mineral corrections.
///
/// Captures:
/// - Selected actual mineral from the searchable 60-species launch catalog or custom input.
/// - Specimen physical form (rough, tumbled, cut, cabochon, facet).
/// - Verification basis (dealer label, physical hardness/streak test, expert named, own collection).
/// - Original model prediction candidate shortlist (pre-attached).
/// - Optional gemological observations / field diagnostic notes.
public struct CorrectionSheetView: View {
    public let result: IdentificationResult
    public let scannedImage: UIImage?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var feedbackService: CorrectionFeedbackService
    
    @State private var searchQuery = ""
    @State private var selectedMineralName: String = ""
    @State private var isCustomMineralSelected = false
    @State private var customMineralName = ""
    @State private var selectedForm: SpecimenFormOption = .rough
    @State private var selectedBasis: VerificationBasis = .dealerLabel
    @State private var userNotes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessToast = false
    
    private let database = MineralDatabase.shared
    
    public init(result: IdentificationResult, scannedImage: UIImage?) {
        self.result = result
        self.scannedImage = scannedImage
    }
    
    private var filteredMinerals: [Mineral] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return database.allMinerals
        }
        return database.search(query: q)
    }
    
    private var effectiveCorrectionName: String {
        if isCustomMineralSelected || !customMineralName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customMineralName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedMineralName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var canSubmit: Bool {
        !effectiveCorrectionName.isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerBanner
                        candidateShortlist
                        mineralSearchSection
                        specimenFormSection
                        verificationBasisSection
                        diagnosticNotesSection
                        submitButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Specimen Correction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.amberGold)
                Text("BETA CORRECTION & GROUND TRUTH")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.amberGold)
            }
            
            Text("Mineral Misidentification Feedback")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Help improve catalog accuracy by contributing verified ground-truth labels and field observations.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Pre-Attached Candidate Shortlist
    private var candidateShortlist: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("ORIGINAL MODEL SHORTLIST", systemImage: "cpu")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.cyan)
                Spacer()
                Text("SHA-256: \(String(GeminiVisionService.promptSHA256.prefix(8)))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            VStack(spacing: 8) {
                let candidates = Array(result.candidates.prefix(3))
                ForEach(0..<candidates.count, id: \.self) { idx in
                    candidateRow(index: idx, candidate: candidates[idx])
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func candidateRow(index: Int, candidate: CandidateItem) -> some View {
        let percentage = Int(candidate.score * 100)
        let color = candidate.confidenceBand.themeColor
        return HStack {
            Text("#\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 24, alignment: .leading)
            
            Text(candidate.mineralName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Section 1: True Mineral Selection
    private var mineralSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("1. ACTUAL MINERAL (GROUND TRUTH)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.amberGold)
                Spacer()
                if !effectiveCorrectionName.isEmpty {
                    Text(effectiveCorrectionName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.emeraldGreen)
                }
            }
            
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                TextField("Search 60 launch catalog minerals...", text: $searchQuery)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Mineral Search Results Grid / Chips
            let displayList = Array(filteredMinerals.prefix(searchQuery.isEmpty ? 12 : 24))
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(displayList, id: \.name) { mineral in
                        let isSelected = selectedMineralName == mineral.name && !isCustomMineralSelected
                        Button(action: {
                            selectedMineralName = mineral.name
                            isCustomMineralSelected = false
                            customMineralName = ""
                        }) {
                            HStack(spacing: 6) {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.black)
                                }
                                Text(mineral.name)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .black : .white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.amberGold : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.amberGold : Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Custom Mineral Text Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Or specify unlisted mineral / variety:")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack {
                    Image(systemName: "pencil")
                        .foregroundColor(.white.opacity(0.5))
                    TextField("e.g. Larimar, Pietersite, Moldavite, Charoite", text: $customMineralName)
                        .foregroundColor(.white)
                        .onChange(of: customMineralName) { _, newVal in
                            if !newVal.trimmingCharacters(in: .whitespaces).isEmpty {
                                isCustomMineralSelected = true
                                selectedMineralName = ""
                            }
                        }
                }
                .padding(10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCustomMineralSelected ? Color.amberGold.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Section 2: Specimen Form
    private var specimenFormSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. SPECIMEN FORM")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SpecimenFormOption.allCases) { formOpt in
                        let isSel = selectedForm == formOpt
                        Button(action: { selectedForm = formOpt }) {
                            Text(formOpt.displayName)
                                .font(.system(size: 12, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .black : .white.opacity(0.85))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSel ? Color.cyan : Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Section 3: Verification Basis
    private var verificationBasisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3. VERIFICATION BASIS")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                ForEach(VerificationBasis.allCases) { basis in
                    let isSel = selectedBasis == basis
                    Button(action: { selectedBasis = basis }) {
                        HStack(spacing: 12) {
                            Image(systemName: basis.icon)
                                .font(.system(size: 15))
                                .foregroundColor(isSel ? .amberGold : .white.opacity(0.5))
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(basis.displayName)
                                    .font(.system(size: 13, weight: isSel ? .bold : .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            if isSel {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.amberGold)
                            }
                        }
                        .padding(12)
                        .background(isSel ? Color.amberGold.opacity(0.12) : Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSel ? Color.amberGold.opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Section 4: Gemological Diagnostic Notes
    private var diagnosticNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4. DIAGNOSTIC OBSERVATIONS (OPTIONAL)")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Describe distinguishing features (e.g. Mohs 7 scratch test passed, white streak, conchoidal fracture, purchased at Tucson show)", text: $userNotes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(3...5)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: submitCorrection) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Submit Verified Ground Truth")
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(canSubmit ? Color.amberGold : Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit || isSubmitting)
        .padding(.top, 4)
        .padding(.bottom, 24)
    }
    
    private func submitCorrection() {
        guard canSubmit else { return }
        isSubmitting = true
        
        let photo = scannedImage?.jpegData(compressionQuality: 0.8)
        let trueMineral = String(effectiveCorrectionName.prefix(100)).trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedNotes = String(userNotes.prefix(1000)).trimmingCharacters(in: .whitespacesAndNewlines)
        
        feedbackService.submitCorrection(
            result: result,
            photoData: photo,
            correctedMineral: trueMineral,
            form: selectedForm.rawValue,
            verificationBasis: selectedBasis.rawValue,
            notes: sanitizedNotes
        )
        
        isSubmitting = false
        dismiss()
    }
}
