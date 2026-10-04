import SwiftUI

/// Screen 6: Full offline encyclopedia profile detailing gemological specs,
/// separating tests, lookalikes, care warnings, and geological context.
public struct MineralDetailView: View {
    public let mineral: Mineral
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLookalike: Mineral?
    @State private var showLookalikeSheet = false
    
    public init(mineral: Mineral) {
        self.mineral = mineral
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Header Banner
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(mineral.category.rawValue, systemImage: mineral.category.icon)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cyan.opacity(0.12))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    
                    Text(mineral.name)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(mineral.chemicalFormula)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                    
                    if !mineral.alternativeNames.isEmpty {
                        Text("AKA: " + mineral.alternativeNames.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    
                    Text(mineral.summary)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
                .padding(18)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Mohs Hardness Scale Visualizer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.cyan)
                        Text("MOHS HARDNESS: \(mineral.mohsHardness)")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 10)
                            
                            let fillWidth = max(0.1, CGFloat(mineral.maxHardness / 10.0)) * geo.size.width
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .indigo, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillWidth, height: 10)
                        }
                    }
                    .frame(height: 10)
                    
                    HStack {
                        Text("1 (Talc)")
                        Spacer()
                        Text("5 (Apatite)")
                        Spacer()
                        Text("7 (Quartz)")
                        Spacer()
                        Text("10 (Diamond)")
                    }
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Physical Gemological Specs Matrix
                VStack(alignment: .leading, spacing: 12) {
                    Text("PHYSICAL & OPTICAL SPECIFICATIONS")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        SpecPropertyItem(title: "Crystal System", value: mineral.crystalSystem)
                        SpecPropertyItem(title: "Specific Gravity", value: mineral.specificGravity)
                        SpecPropertyItem(title: "Luster", value: mineral.luster)
                        SpecPropertyItem(title: "Streak", value: mineral.streak)
                        SpecPropertyItem(title: "Cleavage", value: mineral.cleavage)
                        SpecPropertyItem(title: "Fracture", value: mineral.fracture)
                        SpecPropertyItem(title: "Transparency", value: mineral.transparency)
                        SpecPropertyItem(title: "Refractive Index", value: mineral.refractiveIndex ?? "N/A")
                    }
                }
                
                // Color Range & Common Forms
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NATURAL COLOR RANGE")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        FlowLayout(spacing: 6) {
                            ForEach(mineral.colorRange, id: \.self) { color in
                                Text(color)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMMON FORMS")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        FlowLayout(spacing: 6) {
                            ForEach(mineral.commonForms, id: \.self) { form in
                                Text(form.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.cyan.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Lookalikes & Separating Tests Section
                if !mineral.topLookalikes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                                .foregroundColor(.amberGold)
                            Text("LOOKALIKES & SEPARATING TESTS")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.amberGold)
                        }
                        
                        ForEach(mineral.topLookalikes) { lookalike in
                            LookalikeCardView(lookalike: lookalike) {
                                if let target = MineralDatabase.shared.find(byName: lookalike.mineralName) {
                                    self.selectedLookalike = target
                                    self.showLookalikeSheet = true
                                }
                            }
                        }
                    }
                }
                
                // Diagnostic Rule-Out Tests
                if !mineral.ruleOutTests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.cyan)
                            Text("DEFINITIVE RULE-OUT TESTS")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        ForEach(Array(mineral.ruleOutTests.enumerated()), id: \.offset) { idx, test in
                            SeparatingTestCardView(index: idx + 1, testDescription: test)
                        }
                    }
                }
                
                // Care & Safety Warnings
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.coralRed)
                        Text("CARE & PRESERVATION WARNINGS")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.coralRed)
                    }
                    
                    ForEach(mineral.careWarnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.coralRed)
                                .fontWeight(.bold)
                            Text(warning)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    if !mineral.safetyAndHandling.isEmpty {
                        Text("Handling Safety: \(mineral.safetyAndHandling)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.coralRed.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.coralRed.opacity(0.3), lineWidth: 1)
                )
                
                // Geological Origins & Occurrence
                VStack(alignment: .leading, spacing: 10) {
                    Text("GEOLOGICAL FORMATION & LOCALITIES")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Geological Formation:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyan)
                        Text(mineral.geologicalOrigin)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notable Localities:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyan)
                        Text(mineral.rarityAndOccurrence)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle(mineral.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLookalikeSheet) {
            if let lookalikeMin = selectedLookalike {
                NavigationStack {
                    MineralDetailView(mineral: lookalikeMin)
                }
            }
        }
    }
}

private struct SpecPropertyItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// Simple flow layout container for dynamic wrapping tag chips.
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8
    
    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxLineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += maxLineHeight + spacing
                maxLineHeight = 0
            }
            currentX += size.width + spacing
            maxLineHeight = max(maxLineHeight, size.height)
            height = currentY + maxLineHeight
        }
        return CGSize(width: width, height: height)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var maxLineHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += maxLineHeight + spacing
                maxLineHeight = 0
            }
            view.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            maxLineHeight = max(maxLineHeight, size.height)
        }
    }
}
