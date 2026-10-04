import SwiftUI
import SwiftData

/// Screen 4: Identification results for Confirmed (85-96%) or Likely (55-84%) matches.
public struct ResultView: View {
    public let result: IdentificationResult
    public let scannedImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var allowance: ScanAllowanceManager
    
    @State private var selectedMineral: Mineral?
    @State private var showDetailSheet = false
    @State private var showShareSheet = false
    @State private var shareCardImage: UIImage?
    @State private var isSavedToCollection = false
    @State private var selectedForm = "Rough"
    @State private var userNotes = ""
    @State private var showSaveSuccessToast = false
    
    public init(result: IdentificationResult, scannedImage: UIImage?) {
        self.result = result
        self.scannedImage = scannedImage
    }
    
    public var body: some View {
        let mineral = MineralDatabase.shared.find(byName: result.topCandidate.mineralName)
        
        ScrollView {
            VStack(spacing: 20) {
                // Confidence & Identity Banner
                HStack(spacing: 16) {
                    ConfidenceRingView(
                        score: result.mergedConfidence,
                        band: result.confidenceBand,
                        size: 96
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(result.topCandidate.mineralName)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text(mineral?.chemicalFormula ?? "Mineral Specimen")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        Text(result.confidenceBand.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(18)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(result.confidenceBand.themeColor.opacity(0.3), lineWidth: 1)
                )
                
                // Specimen Image Preview
                if let img = scannedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                
                // Quick Gemological Specs
                if let minObj = mineral {
                    HStack(spacing: 12) {
                        SpecimenMetricBox(label: "MOHS HARDNESS", value: minObj.mohsHardness, icon: "shield.fill")
                        SpecimenMetricBox(label: "LUSTER", value: minObj.luster.components(separatedBy: " ").first ?? "Vitreous", icon: "sparkles")
                        SpecimenMetricBox(label: "STREAK", value: minObj.streak.components(separatedBy: " ").first ?? "White", icon: "pencil.tip")
                    }
                }
                
                // Primary Lookalike & Separating Test Preview
                if let lookalike = mineral?.topLookalikes.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TOP LOOKALIKE SEPARATION")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.amberGold)
                        
                        LookalikeCardView(lookalike: lookalike) {
                            self.selectedMineral = MineralDatabase.shared.find(byName: lookalike.mineralName)
                            self.showDetailSheet = true
                        }
                    }
                }
                
                // Form Selector for Saving
                VStack(alignment: .leading, spacing: 10) {
                    Text("SPECIMEN FORM")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Rough", "Tumbled", "Cut / Faceted", "Cabochon", "Geode / Cluster"], id: \.self) { form in
                                Button(action: { selectedForm = form }) {
                                    Text(form)
                                        .font(.system(size: 12, weight: selectedForm == form ? .bold : .medium))
                                        .foregroundColor(selectedForm == form ? .black : .white.opacity(0.8))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedForm == form ? Color.cyan : Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Save to Collection Button
                    Button(action: saveToCollection) {
                        HStack {
                            Image(systemName: isSavedToCollection ? "checkmark.circle.fill" : "plus.circle.fill")
                            Text(isSavedToCollection ? "Saved to Collection" : "Save to My Collection")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSavedToCollection ? Color.emeraldGreen : Color.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSavedToCollection)
                    
                    HStack(spacing: 12) {
                        // Full Details Encyclopedia
                        Button(action: {
                            self.selectedMineral = mineral
                            self.showDetailSheet = true
                        }) {
                            HStack {
                                Image(systemName: "book.pages.fill")
                                Text("Full Details")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Share Card Generator
                        Button(action: {
                            self.shareCardImage = ShareCardGenerator.shared.renderShareCard(
                                specimenImage: scannedImage,
                                mineral: mineral,
                                confidenceScore: result.mergedConfidence,
                                confidenceBand: result.confidenceBand,
                                form: selectedForm
                            )
                            self.showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Share Card")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle("Identification Result")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetailSheet) {
            if let min = selectedMineral {
                NavigationStack {
                    MineralDetailView(mineral: min)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let card = shareCardImage {
                ShareActivitySheet(activityItems: [card])
            }
        }
    }
    
    private func saveToCollection() {
        let photoData = scannedImage?.jpegData(compressionQuality: 0.8)
        let record = SpecimenRecord(
            photoData: photoData,
            mineralName: result.topCandidate.mineralName,
            confidence: result.mergedConfidence,
            confidenceBand: result.confidenceBand,
            notes: userNotes,
            form: selectedForm,
            isFavorite: false,
            userConfirmed: true
        )
        modelContext.insert(record)
        try? modelContext.save()
        withAnimation {
            isSavedToCollection = true
            showSaveSuccessToast = true
        }
    }
}

private struct SpecimenMetricBox: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.cyan)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

public struct ShareActivitySheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
