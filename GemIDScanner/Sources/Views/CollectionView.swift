import SwiftUI
import SwiftData

/// Screen 7: Personal mineral & rock collection grid with filter chips, search,
/// favorite toggling, and specimen detail inspection.
public struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var storeKit: StoreKitService
    @EnvironmentObject private var allowance: ScanAllowanceManager
    
    @Query(sort: \SpecimenRecord.dateAdded, order: .reverse)
    private var specimens: [SpecimenRecord]
    
    @State private var searchText = ""
    @State private var selectedFilter: CollectionFilter = .all
    @State private var selectedSpecimen: SpecimenRecord?
    @State private var showPaywall = false
    
    public enum CollectionFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case rough = "Rough"
        case tumbled = "Tumbled"
        case cut = "Faceted / Cut"
        case geode = "Geode"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    private var filteredSpecimens: [SpecimenRecord] {
        specimens.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.mineralName.localizedCaseInsensitiveContains(searchText) ||
                item.notes.localizedCaseInsensitiveContains(searchText) ||
                (item.originSource?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .favorites:
                matchesFilter = item.isFavorite
            case .rough:
                matchesFilter = item.form.localizedCaseInsensitiveContains("rough")
            case .tumbled:
                matchesFilter = item.form.localizedCaseInsensitiveContains("tumbled")
            case .cut:
                matchesFilter = item.form.localizedCaseInsensitiveContains("cut") || item.form.localizedCaseInsensitiveContains("faceted")
            case .geode:
                matchesFilter = item.form.localizedCaseInsensitiveContains("geode") || item.form.localizedCaseInsensitiveContains("cluster")
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Collection Capacity Indicator Bar
                HStack {
                    if storeKit.isProPurchased {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.amberGold)
                            Text("PRO • UNLIMITED VAULT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text("STORAGE:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(specimens.count) / \(ScanAllowanceManager.freeCollectionLimit) Saved")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(specimens.count >= ScanAllowanceManager.freeCollectionLimit ? .coralRed : .cyan)
                        }
                    }
                    
                    Spacer()
                    
                    if !storeKit.isProPurchased && specimens.count >= 15 {
                        Button("Upgrade to Unlimited") {
                            showPaywall = true
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.amberGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03))
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CollectionFilter.allCases) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 12, weight: selectedFilter == filter ? .bold : .medium))
                                    .foregroundColor(selectedFilter == filter ? .black : .white.opacity(0.8))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedFilter == filter ? Color.cyan : Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                
                // Specimen Grid Content
                if filteredSpecimens.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        Text(searchText.isEmpty ? "No specimens in collection yet" : "No matching specimens")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Text(searchText.isEmpty ? "Scan rocks with the camera to build your personal gem vault." : "Try adjusting your search or filter.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(filteredSpecimens) { specimen in
                                SpecimenCardItem(
                                    specimen: specimen,
                                    onTap: { selectedSpecimen = specimen },
                                    onToggleFavorite: {
                                        specimen.isFavorite.toggle()
                                        try? modelContext.save()
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
            .navigationTitle("My Collection")
            .searchable(text: $searchText, prompt: "Search specimens by name, notes, or origin")
            .sheet(item: $selectedSpecimen) { item in
                NavigationStack {
                    SpecimenDetailSheet(specimen: item)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

private struct SpecimenCardItem: View {
    @Bindable var specimen: SpecimenRecord
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Photo Frame
                ZStack(alignment: .topTrailing) {
                    if let data = specimen.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 140)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                    
                    // Favorite Star Button
                    Button(action: onToggleFavorite) {
                        Image(systemName: specimen.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(specimen.isFavorite ? .yellow : .white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(6)
                }
                
                // Mineral Identity
                VStack(alignment: .leading, spacing: 2) {
                    Text(specimen.mineralName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Text(specimen.form)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("\(Int(specimen.confidence * 100))%")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(specimen.confidenceBand.themeColor)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Detail inspection and editing sheet for a saved SpecimenRecord.
public struct SpecimenDetailSheet: View {
    @Bindable public var specimen: SpecimenRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirm = false
    @State private var showEncyclopedia = false
    
    public var body: some View {
        let mineral = MineralDatabase.shared.find(byName: specimen.mineralName)
        
        ScrollView {
            VStack(spacing: 18) {
                // Photo
                if let data = specimen.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                
                // Identity Banner
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(specimen.mineralName)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(mineral?.chemicalFormula ?? "Mineral")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                    
                    Text("\(Int(specimen.confidence * 100))%")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundColor(specimen.confidenceBand.themeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(specimen.confidenceBand.themeColor.opacity(0.18))
                        .clipShape(Capsule())
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Specimen Metadata Fields
                VStack(spacing: 12) {
                    HStack {
                        Text("Specimen Form:")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Picker("Form", selection: $specimen.form) {
                            ForEach(["Rough", "Tumbled", "Faceted / Cut", "Cabochon", "Geode / Cluster"], id: \.self) { form in
                                Text(form).tag(form)
                            }
                        }
                        .tint(.cyan)
                    }
                    
                    HStack {
                        Text("Date Added:")
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(specimen.dateAdded.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Field Notes / Origin Location:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        TextField("e.g. Found near creek trail, Mojave Desert", text: $specimen.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Encyclopedia Link
                if let min = mineral {
                    Button(action: { showEncyclopedia = true }) {
                        HStack {
                            Image(systemName: "book.pages.fill")
                            Text("Open Offline Encyclopedia Page")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.cyan.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Delete Specimen Button
                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Specimen from Collection")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.coralRed)
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle("Specimen Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to save specimen changes: \(error.localizedDescription)")
                    }
                    dismiss()
                }
            }
        }
        .confirmationDialog("Delete Specimen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(specimen)
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to delete specimen: \(error.localizedDescription)")
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this rock specimen from your collection?")
        }
        .sheet(isPresented: $showEncyclopedia) {
            if let min = mineral {
                NavigationStack {
                    MineralDetailView(mineral: min)
                }
            }
        }
    }
}
