import SwiftUI
import SwiftData

/// Screen 4: Identification results for Confirmed (85-96%) or Likely (55-84%) matches.
public struct ResultView: View {
    public let result: IdentificationResult
    public let scannedImage: UIImage?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var allowance: ScanAllowanceManager
    @EnvironmentObject private var storeKit: StoreKitService
    
    @Query private var existingSpecimens: [SpecimenRecord]
    
    @State private var selectedMineral: Mineral?
    @State private var showDetailSheet = false
    @State private var showShareSheet = false
    @State private var showPaywallSheet = false
    @State private var showCorrectionSheet = false
    @State private var showSecondAngleBanner = false
    @State private var shareCardImage: UIImage?
    @State private var selectedShareRatio: ShareCardAspectRatio = .story9x16
    @State private var isSavedToCollection = false
    @State private var selectedForm = "Rough"
    @State private var userNotes = ""
    @State private var weightString = ""
    @State private var originSource = ""
    @State private var showSaveSuccessToast = false
    @State private var showAdditionalFields = false
    
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
                
                // Likely Match Optional Second Angle Trigger (55-84%)
                if result.confidenceBand == .likely {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.amberGold)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Likely Match (55-84%)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Add a 45° angle photo to inspect crystal termination and boost certainty.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.rotate.fill")
                                Text("Add 45° angle for higher certainty")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.amberGold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(12)
                    .background(Color.amberGold.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.amberGold.opacity(0.35), lineWidth: 1)
                    )
                }
                
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
                
                // Form & Specimen Metadata for Saving
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
                    
                    // Optional metadata toggle
                    Button(action: { withAnimation { showAdditionalFields.toggle() } }) {
                        HStack {
                            Image(systemName: showAdditionalFields ? "chevron.up.circle" : "plus.circle")
                            Text(showAdditionalFields ? "Hide Custom Details" : "Add Notes, Weight & Origin Location")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan)
                    }
                    .padding(.top, 4)
                    
                    if showAdditionalFields {
                        VStack(spacing: 8) {
                            TextField("Weight in grams (e.g. 14.5)", text: $weightString)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            
                            TextField("Origin Source / Locality (e.g. Mojave Desert)", text: $originSource)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Field notes / diagnostic observations", text: $userNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                        }
                        .padding(.top, 2)
                    }
                }
                
                // Action Buttons: Save, Details, Retake, Share
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
                    
                    HStack(spacing: 10) {
                        // Full Details Encyclopedia
                        Button(action: {
                            self.selectedMineral = mineral
                            self.showDetailSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages.fill")
                                Text("Details")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Retake Scan Button
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                Text("Retake")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Share Card Generator (9:16 / 1:1)
                        Menu {
                            Button("Share 9:16 Story / Reel Card") {
                                generateAndShareCard(ratio: .story9x16, mineral: mineral)
                            }
                            Button("Share 1:1 Square Feed Card") {
                                generateAndShareCard(ratio: .square1x1, mineral: mineral)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Share")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // 'Not my stone?' Easily Accessible Secondary Action
                    Button(action: { showCorrectionSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(.amberGold)
                            Text("Not my stone? Suggest correction")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.amberGold.opacity(0.4), lineWidth: 1)
                        )
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
    
    private func generateAndShareCard(ratio: ShareCardAspectRatio, mineral: Mineral?) {
        self.selectedShareRatio = ratio
        self.shareCardImage = ShareCardGenerator.shared.renderShareCard(
            specimenImage: scannedImage,
            mineral: mineral,
            confidenceScore: result.mergedConfidence,
            confidenceBand: result.confidenceBand,
            form: selectedForm,
            separatingTest: result.separatingTests.first,
            aspectRatio: ratio
        )
        self.showShareSheet = true
    }
    
    private func saveToCollection() {
        guard allowance.canAddToCollection(currentCollectionCount: existingSpecimens.count) else {
            showPaywallSheet = true
            return
        }
        
        let photoData = scannedImage?.jpegData(compressionQuality: 0.8)
        let weight = Double(weightString)
        let record = SpecimenRecord(
            photoData: photoData,
            mineralName: result.topCandidate.mineralName,
            confidence: result.mergedConfidence,
            confidenceBand: result.confidenceBand,
            notes: userNotes,
            weightGrams: weight,
            originSource: originSource.isEmpty ? nil : originSource,
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
