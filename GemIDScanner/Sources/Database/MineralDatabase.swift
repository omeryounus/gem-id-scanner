import Foundation

/// Comprehensive offline database containing 60 accurately categorized launch minerals
/// with physical gemological specs, diagnostic separating tests, and care warnings.
public final class MineralDatabase: @unchecked Sendable {
    public static let shared = MineralDatabase()
    
    public let allMinerals: [Mineral]
    private let indexByName: [String: Mineral]
    
    public init() {
        let minerals = MineralDatabase.buildLaunchCatalog()
        self.allMinerals = minerals
        var dict: [String: Mineral] = [:]
        for mineral in minerals {
            dict[mineral.name.lowercased()] = mineral
            for alt in mineral.alternativeNames {
                dict[alt.lowercased()] = mineral
            }
        }
        self.indexByName = dict
    }
    
    public func find(byName name: String) -> Mineral? {
        indexByName[name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }
    
    public func minerals(in category: MineralCategory) -> [Mineral] {
        allMinerals.filter { $0.category == category }
    }
    
    public func search(query: String) -> [Mineral] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allMinerals }
        return allMinerals.filter { m in
            m.name.lowercased().contains(q) ||
            m.family.lowercased().contains(q) ||
            m.chemicalFormula.lowercased().contains(q) ||
            m.alternativeNames.contains { $0.lowercased().contains(q) } ||
            m.colorRange.contains { $0.lowercased().contains(q) }
        }
    }
    
    // MARK: - 60 Launch Minerals Builder
    private static func buildLaunchCatalog() -> [Mineral] {
        var catalog: [Mineral] = []
        
        // ==========================================
        // 1. QUARTZ FAMILY (8)
        // ==========================================
        catalog.append(Mineral(
            name: "Amethyst",
            alternativeNames: ["Purple Quartz", "Bishop's Stone"],
            category: .quartzFamily,
            family: "Quartz (Tectosilicates)",
            chemicalFormula: "SiO₂ with trace Fe³⁺ / irradiation centers",
            crystalSystem: "Trigonal (hexagonal prisms with rhombohedral terminations)",
            mohsHardness: "7.0",
            minHardness: 7.0,
            maxHardness: 7.0,
            specificGravity: "2.65",
            luster: "Vitreous (glass-like)",
            streak: "White",
            cleavage: "None (indistinct)",
            fracture: "Conchoidal",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.544 - 1.553",
            colorRange: ["Lilac", "Lavender", "Deep Violet", "Grape Purple", "Reddish-Violet"],
            commonForms: [.geode, .rough, .tumbled, .cut, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Purple Fluorite",
                    visualDifference: "Fluorite has cubic crystals, vitreous-to-subdued luster, and prominent 4-directional cleavage.",
                    separatingTest: "Mohs Scratch Test: Fluorite (Mohs 4) is easily scratched by a copper coin or pocket knife; Amethyst (Mohs 7) cannot be scratched by steel.",
                    hardnessComparison: "Amethyst 7.0 vs Fluorite 4.0",
                    diagnosticReaction: "Amethyst scratches glass vigorously; Fluorite cannot scratch glass."
                ),
                Lookalike(
                    mineralName: "Cordierite (Iolite)",
                    visualDifference: "Iolite exhibits strong pleochroism (shifts violet-blue to yellow-gray when rotated).",
                    separatingTest: "Pleochroism Inspection: Look at stone from orthogonal angles with a polarizing filter.",
                    hardnessComparison: "Amethyst 7.0 vs Iolite 7.0 - 7.5",
                    diagnosticReaction: "Refractive index test: Iolite RI is 1.53 - 1.55 with biaxial optic character."
                ),
                Lookalike(
                    mineralName: "Purple Scapolite",
                    visualDifference: "Scapolite exhibits distinct prismatic cleavage and lower hardness.",
                    separatingTest: "Hardness test: Scapolite is Mohs 5.5 - 6.0; scratched by quartz.",
                    hardnessComparison: "Amethyst 7.0 vs Scapolite 5.5 - 6.0",
                    diagnosticReaction: "Scapolite shows strong yellow or pink UV fluorescence under longwave UV."
                )
            ],
            ruleOutTests: [
                "Hardness Test: Scratch test against standard window glass (Mohs 5.5). Must easily score glass without powdering.",
                "Cleavage Check: Check broken surfaces for smooth curved conchoidal fracture (no flat step cleavages).",
                "Acid Test: Insoluble in dilute hydrochloric acid or vinegar."
            ],
            careWarnings: [
                "Avoid prolonged direct sunlight: high heat and UV exposure will bleach purple color to pale yellow/brown.",
                "Safe in water, but geode matrix backing may loosen if soaked long-term."
            ],
            summary: "The most coveted variety of quartz, amethyst derives its iconic purple coloration from natural irradiation of trace ferric iron (Fe³⁺) ions within the quartz lattice.",
            geologicalOrigin: "Forms inside gas cavities (geodes) in basalt lavas and hydrothermal veins.",
            rarityAndOccurrence: "Abundant worldwide; premier deposits in Brazil, Uruguay, Zambia, and Arizona."
        ))

        catalog.append(Mineral(
            name: "Rose Quartz",
            alternativeNames: ["Pink Quartz"],
            category: .quartzFamily,
            family: "Quartz (Tectosilicates)",
            chemicalFormula: "SiO₂ with nanoscopic dumortierite / titanium borosilicate inclusions",
            crystalSystem: "Trigonal (massive crystalline aggregates; rarely euhedral crystals)",
            mohsHardness: "7.0",
            minHardness: 7.0,
            maxHardness: 7.0,
            specificGravity: "2.65",
            luster: "Vitreous to greasy",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal to uneven",
            transparency: "Translucent to Semi-transparent",
            refractiveIndex: "1.544 - 1.553",
            colorRange: ["Baby Pink", "Rose", "Soft Peach", "Deep Blush Pink"],
            commonForms: [.rough, .tumbled, .cabochon, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Pink Calcite (Manganoan)",
                    visualDifference: "Manganoan calcite has rhombohedral cleavage steps and chalkier luster.",
                    separatingTest: "Vinegar / Dilute Acid Test: Calcite fizzes vigorously in warm vinegar; Rose Quartz is completely inert.",
                    hardnessComparison: "Rose Quartz 7.0 vs Calcite 3.0",
                    diagnosticReaction: "Manganoan calcite fluoresces intense hot pink under Shortwave UV."
                ),
                Lookalike(
                    mineralName: "Rhodochrosite",
                    visualDifference: "Rhodochrosite features distinct white banding and deeper raspberry hues.",
                    separatingTest: "Hardness test: Rhodochrosite (Mohs 3.5 - 4) is scratched by a copper coin.",
                    hardnessComparison: "Rose Quartz 7.0 vs Rhodochrosite 3.5 - 4.0",
                    diagnosticReaction: "Rhodochrosite reacts to warm dilute HCl."
                ),
                Lookalike(
                    mineralName: "Pink Opal",
                    visualDifference: "Pink opal exhibits a porcelain-like waxy sheen without crystalline transparency.",
                    separatingTest: "Hardness and density: Pink Opal is softer (Mohs 5.5 - 6.0) and lighter (SG 2.1).",
                    hardnessComparison: "Rose Quartz 7.0 vs Opal 5.5 - 6.0"
                )
            ],
            ruleOutTests: [
                "Knife scratch: Steel knife (Mohs 5.5) will NOT leave a scratch on rose quartz.",
                "Acid effervescence: Zero reaction when drop of 5% vinegar is applied."
            ],
            careWarnings: [
                "Prolonged exposure to direct UV sunlight can cause gradual fading of soft pink tones.",
                "Avoid thermal shock from rapid hot-to-cold water transitions."
            ],
            summary: "A cloudy to translucent pink variety of macrocrystalline quartz. Its color is caused by fibrous microscopic inclusions of a dumortierite-related borosilicate.",
            geologicalOrigin: "Crystallizes in granitic pegmatites and hydrothermal veins.",
            rarityAndOccurrence: "Common; major commercial sources include Brazil, Madagascar, South Africa, and Maine, USA."
        ))

        catalog.append(Mineral(
            name: "Smoky Quartz",
            alternativeNames: ["Cairngorm", "Morion (black variety)"],
            category: .quartzFamily,
            family: "Quartz (Tectosilicates)",
            chemicalFormula: "SiO₂ with aluminum substitution centers",
            crystalSystem: "Trigonal",
            mohsHardness: "7.0",
            minHardness: 7.0,
            maxHardness: 7.0,
            specificGravity: "2.65",
            luster: "Vitreous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Transparent to nearly Opaque",
            refractiveIndex: "1.544 - 1.553",
            colorRange: ["Smoky Grey", "Whiskey Brown", "Amber Brown", "Pitch Black"],
            commonForms: [.rough, .cut, .tumbled, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Black Obsidian",
                    visualDifference: "Obsidian is volcanic glass with razor-sharp curved fracture edges and no crystal faces.",
                    separatingTest: "Hardness test: Obsidian is Mohs 5.0 - 5.5 (scratched by quartz); Smoky quartz is Mohs 7.0.",
                    hardnessComparison: "Smoky Quartz 7.0 vs Obsidian 5.0 - 5.5"
                ),
                Lookalike(
                    mineralName: "Black Tourmaline (Schorl)",
                    visualDifference: "Tourmaline forms elongated striated triangular/hexagonal prisms.",
                    separatingTest: "Cross-section shape: Tourmaline crystals have rounded triangular 3-sided cross-sections; Quartz has 6-sided hexagonal cross-sections.",
                    hardnessComparison: "Smoky Quartz 7.0 vs Tourmaline 7.0 - 7.5"
                ),
                Lookalike(
                    mineralName: "Brown Topaz",
                    visualDifference: "Topaz has a basal cleavage plane and feels noticeably heavier (SG 3.53).",
                    separatingTest: "Heft / Specific Gravity: Topaz is 33% heavier than smoky quartz of equal volume.",
                    hardnessComparison: "Topaz (Mohs 8) will scratch Smoky Quartz (Mohs 7)."
                )
            ],
            ruleOutTests: [
                "Hexagonal crystal symmetry: Look for 6 prismatic faces meeting at 6-sided pyramid apex.",
                "Glass scratch test: Easily scratches bottle glass with negligible resistance."
            ],
            careWarnings: [
                "Do not heat beyond 300°C as thermal treatment will discharge the aluminum color centers and bleach to clear.",
                "Safe for water and standard jewelry cleaning."
            ],
            summary: "A brownish-gray to deep smoky black variety of quartz produced when natural background radiation from surrounding granite activates aluminum impurities.",
            geologicalOrigin: "Found in granite pegmatite pockets, alpine quartz veins, and metamorphic quartzites.",
            rarityAndOccurrence: "Widespread; Switzerland (Alps), Scotland (Cairngorms), Brazil, Colorado (Pikes Peak)."
        ))

        catalog.append(Mineral(
            name: "Citrine",
            alternativeNames: ["Golden Quartz", "Sun Quartz"],
            category: .quartzFamily,
            family: "Quartz (Tectosilicates)",
            chemicalFormula: "SiO₂ with trace Fe³⁺",
            crystalSystem: "Trigonal",
            mohsHardness: "7.0",
            minHardness: 7.0,
            maxHardness: 7.0,
            specificGravity: "2.65",
            luster: "Vitreous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Transparent",
            refractiveIndex: "1.544 - 1.553",
            colorRange: ["Pale Yellow", "Lemon", "Honey Gold", "Amber Orange", "Madeira Red-Orange"],
            commonForms: [.cut, .rough, .tumbled, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Heat-Treated Amethyst (Fake Citrine)",
                    visualDifference: "Heat-treated amethyst has an unnatural burnt-orange or brownish hue with white opaque tooth bases.",
                    separatingTest: "Color distribution inspection: Natural citrine is uniform pale smoky champagne yellow without opaque white basal points.",
                    hardnessComparison: "Both Mohs 7.0"
                ),
                Lookalike(
                    mineralName: "Yellow Topaz",
                    visualDifference: "Topaz displays superior brilliance, distinct basal cleavage, and higher specific gravity.",
                    separatingTest: "Hardness test: Topaz (Mohs 8) scratches Quartz (Mohs 7).",
                    hardnessComparison: "Citrine 7.0 vs Topaz 8.0"
                ),
                Lookalike(
                    mineralName: "Yellow Calcite",
                    visualDifference: "Calcite shows waxy luster and distinct 75° cleavage rhombs.",
                    separatingTest: "Scratch test: Calcite is scratched by a fingernail or copper penny (Mohs 3).",
                    hardnessComparison: "Citrine 7.0 vs Calcite 3.0",
                    diagnosticReaction: "Calcite effervesces in vinegar; Citrine is completely inert."
                )
            ],
            ruleOutTests: [
                "Hardness scratch test: Scratches window glass with zero chipping on the point.",
                "Pleochroism check: Natural citrine shows weak dichroism (yellow to greenish-yellow)."
            ],
            careWarnings: [
                "Keep away from excessive heat which can cause discoloration.",
                "Safe for water immersion and standard soap cleansers."
            ],
            summary: "Natural citrine is a rare yellow variety of crystalline quartz. Most commercial citrine is produced by baking amethyst at 450°C-500°C.",
            geologicalOrigin: "Forms in granitic pegmatites and hydrothermal quartz veins.",
            rarityAndOccurrence: "Natural citrine is rare; found in Madagascar, Brazil (Rio Grande do Sul), Russia (Urals)."
        ))

        catalog.append(Mineral(
            name: "Clear Quartz",
            alternativeNames: ["Rock Crystal", "Pure Quartz"],
            category: .quartzFamily,
            family: "Quartz (Tectosilicates)",
            chemicalFormula: "SiO₂",
            crystalSystem: "Trigonal",
            mohsHardness: "7.0",
            minHardness: 7.0,
            maxHardness: 7.0,
            specificGravity: "2.65",
            luster: "Vitreous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Transparent",
            refractiveIndex: "1.544 - 1.553",
            colorRange: ["Colorless", "Water-clear", "Icy white"],
            commonForms: [.rough, .cut, .tumbled, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Glass (Man-made)",
                    visualDifference: "Glass often contains spherical air bubbles and swirl lines, feels warmer to the touch.",
                    separatingTest: "Thermal conductivity / Scratch test: Quartz feels cold to initial touch and easily scratches glass without scratching itself.",
                    hardnessComparison: "Quartz 7.0 vs Glass 5.5",
                    diagnosticReaction: "Polariscope test: Quartz shows 'bull's eye' optic figure; glass is isotropic."
                ),
                Lookalike(
                    mineralName: "Danburite",
                    visualDifference: "Danburite forms diamond-shaped prismatic terminations and shows blue-green luminescence.",
                    separatingTest: "Hardness test: Danburite (Mohs 7.0 - 7.5) slightly scratches quartz.",
                    hardnessComparison: "Clear Quartz 7.0 vs Danburite 7.5"
                ),
                Lookalike(
                    mineralName: "Goshenite (Clear Beryl)",
                    visualDifference: "Beryl crystal prisms are flat-topped hexagonal basal pinacoids without 6-pointed pyramids.",
                    separatingTest: "Hardness & termination geometry: Goshenite is Mohs 7.5 - 8.0.",
                    hardnessComparison: "Clear Quartz 7.0 vs Goshenite 7.5 - 8.0"
                )
            ],
            ruleOutTests: [
                "Hexagonal crystal striations: Quartz prisms feature horizontal growth striations along the prism faces.",
                "Mohs 7 check: Cannot be scratched by pocket knife, steel nail, or masonry drill bit."
            ],
            careWarnings: [
                "Durable and inert to all everyday household chemicals except hydrofluoric acid.",
                "Safe for water, sunlight, and ultrasonic cleaning."
            ],
            summary: "Pure silicon dioxide without chemical color impurities. Master crystal benchmark of mineral hardness (Mohs 7.0) and optical piezoelectricity.",
            geologicalOrigin: "Ubiquitous in hydrothermal veins, pegmatites, and sedimentary geodes.",
            rarityAndOccurrence: "Extremely abundant worldwide; Arkansas (Mt. Ida), Brazil (Minas Gerais), Alps."
        ))

        catalog.append(Mineral(
            name: "Agate",
            alternativeNames: ["Banded Chalcedony"],
            category: .quartzFamily,
            family: "Quartz (Microcrystalline / Chalcedony)",
            chemicalFormula: "SiO₂",
            crystalSystem: "Trigonal (microcrystalline aggregate)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.60 - 2.64",
            luster: "Waxy to vitreous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Translucent to Semi-opaque",
            refractiveIndex: "1.530 - 1.540",
            colorRange: ["White", "Grey", "Blue", "Banded Red", "Brown", "Orange", "Black"],
            commonForms: [.rough, .tumbled, .cabochon, .carved, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Banded Calcite (Onyx Marble)",
                    visualDifference: "Often sold commercially as 'Mexican Onyx' or 'Green Onyx', calcite bands are softer and chalkier.",
                    separatingTest: "Acid Fizz Test: Banded calcite fizzes instantly with vinegar; true agate is non-reactive.",
                    hardnessComparison: "Agate 7.0 vs Banded Calcite 3.0"
                ),
                Lookalike(
                    mineralName: "Banded Fluorite",
                    visualDifference: "Fluorite bands are cubic in origin with intense vibrant purple/green tones and low hardness.",
                    separatingTest: "Scratch test: Fluorite is Mohs 4 and is scored deeply by a copper coin or pocket knife.",
                    hardnessComparison: "Agate 7.0 vs Fluorite 4.0"
                ),
                Lookalike(
                    mineralName: "Jasper",
                    visualDifference: "Jasper is completely opaque due to high clay/iron content (up to 20%); agate has translucent zones.",
                    separatingTest: "Backlighting / Flashlight test: Light passes through agate edges; jasper remains 100% opaque.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Backlight test: Hold phone flashlight directly behind stone; concentric rhythmic bands must allow diffused light to pass through.",
                "Knife scratch: Pocket knife cannot scratch the surface."
            ],
            careWarnings: [
                "Very durable. Dyed agates (common electric neon pinks/blues) may fade if exposed to harsh acetone or prolonged sunlight.",
                "Safe for water washing."
            ],
            summary: "A banded microcrystalline quartz formed in repetitive rhythmic layers inside gas vesicles of volcanic lava.",
            geologicalOrigin: "Precipitation of silica gels inside cooling volcanic basalt cavities.",
            rarityAndOccurrence: "Common; Lake Superior (USA), Brazil, Botswana, Germany (Idar-Oberstein)."
        ))

        catalog.append(Mineral(
            name: "Chalcedony",
            alternativeNames: ["Microcrystalline Quartz", "Blue Chalcedony"],
            category: .quartzFamily,
            family: "Quartz (Microcrystalline)",
            chemicalFormula: "SiO₂ with moganite intergrowths",
            crystalSystem: "Trigonal / Monoclinic moganite",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.58 - 2.64",
            luster: "Waxy to dull",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal to splintery",
            transparency: "Translucent to Semi-opaque",
            refractiveIndex: "1.530 - 1.539",
            colorRange: ["Lavender-Blue", "Milky Grey", "White", "Pale Sage Green", "Tan"],
            commonForms: [.tumbled, .cabochon, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Common Opal (Potch)",
                    visualDifference: "Opal has lower density and a softer, more gelatinous luster.",
                    separatingTest: "Specific gravity and Mohs: Opal is Mohs 5.5 - 6.0 and SG 2.10 (floats in bromoform); Chalcedony is SG 2.60.",
                    hardnessComparison: "Chalcedony 7.0 vs Opal 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Nephrite Jade",
                    visualDifference: "Nephrite has an interlocking fibrous felted texture with higher toughness.",
                    separatingTest: "Refractive index: Nephrite RI is 1.61; Chalcedony RI is 1.535.",
                    hardnessComparison: "Chalcedony 7.0 vs Nephrite 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Larimar",
                    visualDifference: "Larimar has needle-like radiating pectolite spray structure and lower hardness.",
                    separatingTest: "Hardness test: Larimar (Mohs 4.5 - 5.0) is easily scratched by a steel nail.",
                    hardnessComparison: "Chalcedony 7.0 vs Larimar 4.5 - 5.0"
                )
            ],
            ruleOutTests: [
                "Botryoidal habit: In rough form, look for grape-cluster rounded bubbly outer surface crusts.",
                "Hardness: Scratches steel needle without leaving a powdered groove."
            ],
            careWarnings: [
                "Highly resistant to chemicals; safe in warm soapy water.",
                "Porous varieties may absorb harsh dark dyes or oils."
            ],
            summary: "A cryptocrystalline form of silica composed of sub-microscopic quartz fibers intergrown with moganite, offering a soft glowing translucency.",
            geologicalOrigin: "Low-temperature silica precipitates in sedimentary and volcanic rock cavities.",
            rarityAndOccurrence: "Widespread; Turkey, Namibia, USA (Oregon, California), India."
        ))

        catalog.append(Mineral(
            name: "Jasper",
            alternativeNames: ["Red Jasper", "Ocean Jasper", "Picture Jasper"],
            category: .quartzFamily,
            family: "Quartz (Microcrystalline / Impure)",
            chemicalFormula: "SiO₂ with up to 20% Fe₂O₃ / clay impurities",
            crystalSystem: "Trigonal (microcrystalline)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.58 - 2.91",
            luster: "Dull to vitreous",
            streak: "White to pale yellow/reddish",
            cleavage: "None",
            fracture: "Conchoidal to uneven",
            transparency: "Opaque",
            refractiveIndex: "1.540",
            colorRange: ["Brick Red", "Mustard Yellow", "Earthy Brown", "Forest Green", "Mottled Orbicular"],
            commonForms: [.rough, .tumbled, .cabochon, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Chert / Flint",
                    visualDifference: "Chert is usually drab grey/black and forms chalky nodules in limestone.",
                    separatingTest: "Geological context & color saturation: Jasper is richly colored by iron oxides; flint is sedimentary siliceous stone.",
                    hardnessComparison: "Both Mohs 7.0"
                ),
                Lookalike(
                    mineralName: "MookReporting Siltstone / Mudstone",
                    visualDifference: "Mudstone is much softer and has a clay-like earthy odor when breathed upon.",
                    separatingTest: "Hardness test: Mudstone scratches at Mohs 2 - 3; Jasper is Mohs 6.5 - 7.",
                    hardnessComparison: "Jasper 7.0 vs Mudstone 2.5"
                ),
                Lookalike(
                    mineralName: "Red Marble",
                    visualDifference: "Red marble consists of calcite crystals and fizzes in acid.",
                    separatingTest: "Acid test: Red marble effervesces in vinegar; Jasper does not react.",
                    hardnessComparison: "Jasper 7.0 vs Red Marble 3.0"
                )
            ],
            ruleOutTests: [
                "100% Opacity Test: Flashlight held against stone face cannot shine light through even razor-thin edges.",
                "Steel knife scratch: Blade skates across surface without scratching."
            ],
            careWarnings: [
                "Exceptionally tough and durable; perfect for everyday jewelry wear.",
                "Safe for all standard cleaning methods."
            ],
            summary: "An opaque, microcrystalline variety of quartz packed with up to 20% mineral oxides and clays, producing endless patterns and earth tones.",
            geologicalOrigin: "Volcanic ash beds, banded iron formations, and hydrothermal sediments.",
            rarityAndOccurrence: "Very common; Madagascar, Australia, USA (Idaho, Oregon), South Africa."
        ))

        // ==========================================
        // 2. EVERYDAY FINDS (14)
        // ==========================================
        catalog.append(Mineral(
            name: "Pyrite",
            alternativeNames: ["Fool's Gold", "Iron Pyrite"],
            category: .everydayFinds,
            family: "Sulfide Minerals",
            chemicalFormula: "FeS₂",
            crystalSystem: "Isometric (cubes, pyritohedrons, octahedral faces with striations)",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "4.95 - 5.10",
            luster: "Brilliant Metallic",
            streak: "Greenish-black to brownish-black",
            cleavage: "Indistinct (parting on {011})",
            fracture: "Conchoidal to uneven; brittle",
            transparency: "Opaque",
            refractiveIndex: "N/A (Opaque)",
            colorRange: ["Brass Yellow", "Pale Gold", "Tarnished Bronze"],
            commonForms: [.rough, .geode, .carved, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Native Gold",
                    visualDifference: "Gold is deep warm yellow, sectile, malleable (dents under hammer), while pyrite is brittle and shatters.",
                    separatingTest: "Streak & Malleability: Pyrite leaves a black/greenish-black streak; real gold leaves a shiny golden-yellow streak and flattens without shattering.",
                    hardnessComparison: "Pyrite (Mohs 6 - 6.5) vs Gold (Mohs 2.5 - 3.0)",
                    diagnosticReaction: "Pyrite sparks when struck against steel; gold does not spark."
                ),
                Lookalike(
                    mineralName: "Chalcopyrite (Peacock Ore)",
                    visualDifference: "Chalcopyrite has a deeper golden hue with iridescent purple/blue peacock tarnish.",
                    separatingTest: "Hardness test: Chalcopyrite (Mohs 3.5 - 4.0) is easily scratched by a steel nail; Pyrite (Mohs 6+) scratches steel.",
                    hardnessComparison: "Pyrite 6.5 vs Chalcopyrite 3.5"
                ),
                Lookalike(
                    mineralName: "Marcasite",
                    visualDifference: "Marcasite forms orthorhombic spearhead or cockscomb crystal habits and is paler.",
                    separatingTest: "Crystal habit inspection: Pyrite forms cubes/pyritohedrons; Marcasite forms spearheads.",
                    hardnessComparison: "Both Mohs 6.0 - 6.5"
                )
            ],
            ruleOutTests: [
                "Streak Tile Test: Rub specimen firmly across unglazed ceramic tile. Must produce distinctive greenish-black powder streak.",
                "Strike spark test: Striking with flint or hardened steel generates distinct sulfurous spark."
            ],
            careWarnings: [
                "Do not soak in water: moisture and humidity trigger 'pyrite disease' (oxidation into sulfuric acid and iron sulfate white powder).",
                "Store in a dry, low-humidity environment with silica gel packets."
            ],
            summary: "The classic 'Fool's Gold'. FeS₂ crystals form mirror-metallic cubes and pyritohedrons whose high density and brassy luster deceive casual gold prospectors.",
            geologicalOrigin: "Hydrothermal veins, sedimentary coal beds, and contact metamorphic rocks.",
            rarityAndOccurrence: "Very common; Peru (Huanzala), Spain (Navajun cubes), USA, Germany."
        ))

        catalog.append(Mineral(
            name: "Calcite",
            alternativeNames: ["Calcium Carbonate", "Iceland Spar"],
            category: .everydayFinds,
            family: "Carbonates",
            chemicalFormula: "CaCO₃",
            crystalSystem: "Trigonal (rhombohedrons, scalenohedrons 'dogtooth', prisms)",
            mohsHardness: "3.0",
            minHardness: 3.0,
            maxHardness: 3.0,
            specificGravity: "2.71",
            luster: "Vitreous to pearly on cleavage faces",
            streak: "White",
            cleavage: "Perfect rhombohedral in 3 directions at ~75° angles",
            fracture: "Conchoidal (rarely observed due to easy cleavage)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.486 - 1.658 (Extreme Birefringence 0.172)",
            colorRange: ["Colorless (optical)", "White", "Orange", "Yellow", "Green", "Blue", "Pink (Manganoan)"],
            commonForms: [.rough, .tumbled, .carved, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Quartz",
                    visualDifference: "Quartz has 6-sided hexagonal prisms, lacks cleavage, and does not exhibit double refraction.",
                    separatingTest: "Acid test & Hardness: Calcite (Mohs 3) is scratched by a copper coin and fizzes violently in vinegar; Quartz (Mohs 7) is unaffected.",
                    hardnessComparison: "Calcite 3.0 vs Quartz 7.0",
                    diagnosticReaction: "Vigorous fizzing effervescence with 1 drop of vinegar or dilute 5% HCl."
                ),
                Lookalike(
                    mineralName: "Dolomite",
                    visualDifference: "Dolomite forms curved saddle-shaped crystal faces and is slightly harder (Mohs 3.5 - 4.0).",
                    separatingTest: "Cold acid reaction: Calcite fizzes immediately in cold dilute acid; Dolomite only fizzes when powdered or heated.",
                    hardnessComparison: "Calcite 3.0 vs Dolomite 3.5 - 4.0"
                ),
                Lookalike(
                    mineralName: "Gypsum (Selenite)",
                    visualDifference: "Gypsum is even softer (Mohs 2.0) and can be scratched with a human fingernail.",
                    separatingTest: "Fingernail scratch: Calcite cannot be scratched by a fingernail (2.5); Gypsum scratches with light finger pressure.",
                    hardnessComparison: "Calcite 3.0 vs Gypsum 2.0"
                )
            ],
            ruleOutTests: [
                "Double Refraction Test: Place clear Iceland spar rhomb over printed text on paper; two identical images appear side by side.",
                "Dilute Acid / Vinegar Test: Place single droplet of white vinegar on unpolished corner; rapid bubbling of CO₂ confirms carbonate."
            ],
            careWarnings: [
                "Do not expose to acidic liquids (vinegar, citrus, cleaning sprays) which dissolve the stone.",
                "Soft (Mohs 3): easily scratched by dust, coins, and keys."
            ],
            summary: "One of Earth's most abundant minerals. Renowned for its perfect rhombohedral cleavage, extreme double refraction (birefringence), and effervescence in acid.",
            geologicalOrigin: "Major constituent of sedimentary limestone, chalk, and cave speleothems (stalactites).",
            rarityAndOccurrence: "Ubiquitous globally; Mexico, Iceland, USA (Tennessee, Missouri), China."
        ))

        catalog.append(Mineral(
            name: "Hematite",
            alternativeNames: ["Specularite", "Bloodstone Ore", "Kidney Ore"],
            category: .everydayFinds,
            family: "Oxides",
            chemicalFormula: "Fe₂O₃",
            crystalSystem: "Trigonal",
            mohsHardness: "5.5 - 6.5",
            minHardness: 5.5,
            maxHardness: 6.5,
            specificGravity: "5.26",
            luster: "Metallic to earthy dull submetallic",
            streak: "Distinctive Blood Red to Reddish-Brown",
            cleavage: "None (parting on {001} and {012})",
            fracture: "Subconchoidal to uneven",
            transparency: "Opaque",
            refractiveIndex: "2.90 - 3.22",
            colorRange: ["Gunmetal Silver", "Metallic Steel Grey", "Black", "Rust Red (Earthy)"],
            commonForms: [.tumbled, .rough, .carved, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Magnetite",
                    visualDifference: "Magnetite is strongly magnetic and leaves a black streak.",
                    separatingTest: "Streak test & Magnet check: Hematite gives a bright reddish-brown streak and is only weakly magnetic when heated; Magnetite gives a black streak and strongly attracts magnets.",
                    hardnessComparison: "Hematite 6.0 vs Magnetite 6.0",
                    diagnosticReaction: "Red streak on ceramic tile is 100% diagnostic for hematite."
                ),
                Lookalike(
                    mineralName: "Goethite",
                    visualDifference: "Goethite leaves a yellow-brown (ochre) streak rather than blood red.",
                    separatingTest: "Streak tile: Goethite streak is distinctly mustard-yellow/brown.",
                    hardnessComparison: "Hematite 6.0 vs Goethite 5.0 - 5.5"
                ),
                Lookalike(
                    mineralName: "Hemalyke (Synthetic magnetic imitation)",
                    visualDifference: "Hemalyke is highly magnetic man-made barium-ferrite ceramic sold in novelty gift shops.",
                    separatingTest: "Magnetism: Natural specular hematite does not attract a refrigerator magnet.",
                    hardnessComparison: "Natural Hematite is non-magnetic at room temperature."
                )
            ],
            ruleOutTests: [
                "Streak Tile Test: Drag across back of porcelain tile: MUST leave characteristic rust-red / blood-red line.",
                "Heft Check: Heavy specific gravity (5.26) makes it feel like solid lead in hand."
            ],
            careWarnings: [
                "Earthy varieties may release red dust on hands.",
                "Safe for brief cleaning, but prolonged water immersion can induce surface rust."
            ],
            summary: "The primary ore of iron. Its name derives from Greek 'haima' (blood) due to the vivid blood-red color of its powdered streak, despite its silver-metallic exterior.",
            geologicalOrigin: "Precambrian banded iron formations, sedimentary iron beds, and hydrothermal veins.",
            rarityAndOccurrence: "Abundant; Brazil (Minas Gerais), USA (Lake Superior), South Africa, Australia."
        ))

        catalog.append(Mineral(
            name: "Magnetite",
            alternativeNames: ["Lodestone (naturally magnetized variety)", "Magnetic Iron Ore"],
            category: .everydayFinds,
            family: "Oxides (Spinel Group)",
            chemicalFormula: "Fe₃O₄ (Fe²⁺Fe³⁺₂O₄)",
            crystalSystem: "Isometric (sharp octahedral crystals)",
            mohsHardness: "5.5 - 6.5",
            minHardness: 5.5,
            maxHardness: 6.5,
            specificGravity: "5.18",
            luster: "Metallic to submetallic",
            streak: "Black",
            cleavage: "None (octahedral parting)",
            fracture: "Subconchoidal to uneven",
            transparency: "Opaque",
            refractiveIndex: "N/A",
            colorRange: ["Iron Black", "Dark Charcoal Grey"],
            commonForms: [.rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Hematite",
                    visualDifference: "Hematite leaves a rust-red streak and has weaker or absent ferromagnetism.",
                    separatingTest: "Streak test: Magnetite streak is jet black; Hematite streak is blood red.",
                    hardnessComparison: "Both Mohs 5.5 - 6.5",
                    diagnosticReaction: "Strong attraction to handheld neodymium magnet."
                ),
                Lookalike(
                    mineralName: "Chromite",
                    visualDifference: "Chromite is only weakly magnetic and leaves a dark brown streak.",
                    separatingTest: "Streak color & magnetic pull: Chromite streak is pitch brown with slight magnetic pull.",
                    hardnessComparison: "Magnetite 6.0 vs Chromite 5.5"
                ),
                Lookalike(
                    mineralName: "Franklinite",
                    visualDifference: "Franklinite leaves a reddish-brown to dark brown streak and is associated with fluorescent willemite/calcite.",
                    separatingTest: "UV association test: Franklinite occurs with neon-green fluorescent willemite in New Jersey deposits.",
                    hardnessComparison: "Both Mohs 6.0"
                )
            ],
            ruleOutTests: [
                "Handheld Magnet Test: Must strongly jump to and adhere to an iron magnet.",
                "Black Streak Test: Drag across streak plate to confirm pitch-black line (not red)."
            ],
            careWarnings: [
                "Keep away from magnetic media, pacemakers, and compasses (lodestone variety acts as natural permanent magnet).",
                "Keep dry to prevent oxidation into brownish limonite."
            ],
            summary: "A naturally ferromagnetic iron oxide that crystallizes into distinct 8-sided octahedrons. Ancient sailors used magnetized lodestone chunks as the first magnetic compass needles.",
            geologicalOrigin: "Igneous magmatic segregations, regional metamorphic rocks, and heavy black beach sands.",
            rarityAndOccurrence: "Common; Sweden (Kiruna), South Africa (Bushveld), USA (New York, Utah)."
        ))

        catalog.append(Mineral(
            name: "Gypsum",
            alternativeNames: ["Selenite", "Satin Spar", "Alabaster", "Desert Rose"],
            category: .everydayFinds,
            family: "Sulfates",
            chemicalFormula: "CaSO₄·2H₂O",
            crystalSystem: "Monoclinic (prismatic, tabular, fibrous satin spar, rosette clusters)",
            mohsHardness: "2.0",
            minHardness: 2.0,
            maxHardness: 2.0,
            specificGravity: "2.31 - 2.33",
            luster: "Vitreous, pearly on cleavages, silky (satin spar)",
            streak: "White",
            cleavage: "Perfect in 1 direction {010}, distinct in 2 others",
            fracture: "Splintery to conchoidal",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.520 - 1.530",
            colorRange: ["Clear Colorless", "Silky White", "Sandy Amber", "Desert Tan"],
            commonForms: [.rough, .carved, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Ulexite (TV Rock)",
                    visualDifference: "Ulexite transmits images through fiber optics when placed over text.",
                    separatingTest: "Optical television effect & Hardness: Gypsum satin spar does not transmit upright optical images across thick slabs.",
                    hardnessComparison: "Gypsum 2.0 vs Ulexite 2.5"
                ),
                Lookalike(
                    mineralName: "Calcite",
                    visualDifference: "Calcite cannot be scratched by a fingernail.",
                    separatingTest: "Fingernail scratch test: Gypsum (Mohs 2) is easily scratched with your bare fingernail (Mohs 2.5).",
                    hardnessComparison: "Gypsum 2.0 vs Calcite 3.0",
                    diagnosticReaction: "Gypsum does not fizz in cold vinegar; Calcite fizzes vigorously."
                ),
                Lookalike(
                    mineralName: "Anhydrite",
                    visualDifference: "Anhydrite (CaSO₄ without water) is harder (Mohs 3.5) and has higher density (SG 2.98).",
                    separatingTest: "Hardness: Anhydrite cannot be scratched with fingernail.",
                    hardnessComparison: "Gypsum 2.0 vs Anhydrite 3.5"
                )
            ],
            ruleOutTests: [
                "Fingernail Scratch Test: Press your thumbnail into the edge. Must leave an unmistakable indented groove.",
                "Water Sensitivity Check: Soluble in warm water over time; never submerge."
            ],
            careWarnings: [
                "CRITICAL: Do NOT submerge in water! Gypsum is water-soluble (CaSO₄·2H₂O) and will dissolve, turn cloudy, and lose luster.",
                "Extremely fragile (Mohs 2.0): protect from drops, keys, and coarse dust."
            ],
            summary: "A hydrous calcium sulfate standard for Mohs 2 hardness. Varieties include water-clear optical selenite, silky fibrous satin spar, and desert rose evaporite clusters.",
            geologicalOrigin: "Evaporite deposits in saline lakes, lagoons, and cave formations.",
            rarityAndOccurrence: "Extremely common; Mexico (Naica Giant Crystal Cave), Morocco, USA (Utah, New Mexico)."
        ))

        catalog.append(Mineral(
            name: "Fluorite",
            alternativeNames: ["Fluorspar"],
            category: .everydayFinds,
            family: "Halides",
            chemicalFormula: "CaF₂",
            crystalSystem: "Isometric (cubes, octahedrons, penetration twins)",
            mohsHardness: "4.0",
            minHardness: 4.0,
            maxHardness: 4.0,
            specificGravity: "3.18",
            luster: "Vitreous",
            streak: "White",
            cleavage: "Perfect in 4 directions forming octahedral fragments",
            fracture: "Subconchoidal to splintery",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.434 (Very low)",
            colorRange: ["Purple", "Emerald Green", "Yellow", "Electric Blue", "Banded Rainbow", "Colorless"],
            commonForms: [.rough, .carved, .tumbled, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Amethyst (Purple Quartz)",
                    visualDifference: "Amethyst crystals are hexagonal pyramids; Fluorite forms cubic crystals with 4-way cleavage.",
                    separatingTest: "Hardness test: Pocket knife (Mohs 5.5) or copper coin (Mohs 3.5) scratches Fluorite (Mohs 4) easily, but cannot scratch Amethyst (Mohs 7).",
                    hardnessComparison: "Fluorite 4.0 vs Amethyst 7.0"
                ),
                Lookalike(
                    mineralName: "Green Beryl (Emerald)",
                    visualDifference: "Beryl is hard (Mohs 7.5 - 8.0) and forms hexagonal prisms without octahedral cleavage.",
                    separatingTest: "Hardness: Beryl scratches glass effortlessly; Fluorite cannot scratch glass.",
                    hardnessComparison: "Fluorite 4.0 vs Beryl 7.5 - 8.0"
                ),
                Lookalike(
                    mineralName: "Apatite",
                    visualDifference: "Apatite has higher hardness (Mohs 5) and hexagonal crystal habit.",
                    separatingTest: "Cleavage check: Fluorite breaks along 4 distinct octahedral angles; Apatite has indistinct basal cleavage.",
                    hardnessComparison: "Fluorite 4.0 vs Apatite 5.0"
                )
            ],
            ruleOutTests: [
                "UV Fluorescence: Shine 365nm UV light: fluorite glows intensely violet/blue (the origin of the word 'fluorescence').",
                "Hardness Test: Scratched by steel nail (Mohs 5.0) but scratches calcite (Mohs 3.0)."
            ],
            careWarnings: [
                "Brittle with 4-directional cleavage: shocks and drops will cause internal cleaves and cracks.",
                "Keep away from hot water and prolonged direct sunlight."
            ],
            summary: "The colorful halide CaF₂ that gave birth to the term 'fluorescence'. Crystallizes in perfect cubes and cleaves cleanly into 8-sided octahedrons.",
            geologicalOrigin: "Hydrothermal veins, greisens, and replacement deposits in limestones.",
            rarityAndOccurrence: "Common; UK (Derbyshire Blue John), China (Hunan), USA (Illinois), Germany."
        ))

        catalog.append(Mineral(
            name: "Mica",
            alternativeNames: ["Muscovite (White Mica)", "Biotite (Black Mica)", "Isinglass"],
            category: .everydayFinds,
            family: "Phyllosilicates (Sheet Silicates)",
            chemicalFormula: "KAl₂(AlSi₃O₁₀)(F,OH)₂ (Muscovite) / K(Mg,Fe)₃AlSi₃O₁₀(F,OH)₂ (Biotite)",
            crystalSystem: "Monoclinic (pseudo-hexagonal books and flexible elastic sheets)",
            mohsHardness: "2.5 - 3.0 (parallel to cleavage), 4.0 (across sheets)",
            minHardness: 2.5,
            maxHardness: 3.0,
            specificGravity: "2.76 - 3.10",
            luster: "Vitreous to pearly / metallic sheen",
            streak: "White to pale grey",
            cleavage: "Perfect basal in 1 direction {001}, yielding paper-thin flexible elastic sheets",
            fracture: "Uneven (rarely seen due to sheets)",
            transparency: "Transparent to Translucent in thin sheets",
            refractiveIndex: "1.552 - 1.615",
            colorRange: ["Silvery White", "Clear Gold", "Bronze Brown", "Jet Black (Biotite)", "Pale Green (Fuchsite)"],
            commonForms: [.rough, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Graphite",
                    visualDifference: "Graphite is greasy, leaves a black pencil streak, and its flakes are inelastic (stay bent).",
                    separatingTest: "Elasticity & Streak: Mica sheets snap back elastically when bent; Graphite sheets deform permanently and write black on paper.",
                    hardnessComparison: "Mica 2.5 vs Graphite 1.5"
                ),
                Lookalike(
                    mineralName: "Talc",
                    visualDifference: "Talc feels soapy/greasy and its flakes are flexible but not elastic.",
                    separatingTest: "Hardness & touch: Talc is Mohs 1.0 (soapy); Mica sheets are resilient and springy.",
                    hardnessComparison: "Mica 2.5 - 3.0 vs Talc 1.0"
                ),
                Lookalike(
                    mineralName: "Vermiculite",
                    visualDifference: "Vermiculite expands 10-30x into accordion-like worms when heated with a torch.",
                    separatingTest: "Heat test: Vermiculite exfoliates rapidly upon heating.",
                    hardnessComparison: "Both Mohs 2 - 3"
                )
            ],
            ruleOutTests: [
                "Sheet Peel & Elasticity Test: Carefully lift edge of thin layer with needle; sheet bends flexibly and springs back without breaking.",
                "Thermal resistance: Withstands direct flame without melting or catching fire."
            ],
            careWarnings: [
                "Do not scrub with stiff brushes: delicate sheet edges will fray and flake apart.",
                "Avoid soaking in water which can enter inter-layer crystal sheets."
            ],
            summary: "A sheet-silicate mineral famed for its perfect basal cleavage, allowing it to be split into paper-thin, transparent, thermally insulating flexible sheets.",
            geologicalOrigin: "Granitic pegmatites, schists, and gneisses.",
            rarityAndOccurrence: "Extremely common; India (Bihar), USA (North Carolina), Russia, Brazil."
        ))

        catalog.append(Mineral(
            name: "Galena",
            alternativeNames: ["Lead Glance", "Lead Sulfide"],
            category: .everydayFinds,
            family: "Sulfide Minerals",
            chemicalFormula: "PbS",
            crystalSystem: "Isometric (cubes, cuboctahedrons)",
            mohsHardness: "2.5 - 2.75",
            minHardness: 2.5,
            maxHardness: 2.75,
            specificGravity: "7.58 - 7.60 (Extremely Dense)",
            luster: "Bright Metallic (dulls on oxidized surfaces)",
            streak: "Lead Grey to Black",
            cleavage: "Perfect cubic in 3 directions at exactly 90°",
            fracture: "Subconchoidal to uneven (breaks into tiny shiny cubes)",
            transparency: "Opaque",
            refractiveIndex: "N/A (Opaque)",
            colorRange: ["Lead Grey", "Silver Metallic"],
            commonForms: [.rough, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Hematite (Specular)",
                    visualDifference: "Specular hematite has reddish undertones, lower density, and red streak.",
                    separatingTest: "Streak test: Galena gives lead-grey streak; Hematite gives rust-red streak.",
                    hardnessComparison: "Galena 2.5 vs Hematite 6.0",
                    diagnosticReaction: "Heft: Galena (SG 7.58) is 45% heavier than Hematite (SG 5.26)."
                ),
                Lookalike(
                    mineralName: "Stibnite",
                    visualDifference: "Stibnite forms long slender radiating metallic needles, not cubes.",
                    separatingTest: "Crystal habit: Galena cleaves into 90° cubes; Stibnite forms striated bladed prisms.",
                    hardnessComparison: "Galena 2.5 vs Stibnite 2.0"
                ),
                Lookalike(
                    mineralName: "Sphalerite",
                    visualDifference: "Sphalerite has resinous to submetallic luster, brown streak, and smells of sulfur.",
                    separatingTest: "Streak test: Sphalerite streak is pale brown to yellow with rotten egg odor when scratched with acid.",
                    hardnessComparison: "Galena 2.5 vs Sphalerite 3.5 - 4.0"
                )
            ],
            ruleOutTests: [
                "Extreme Density Heft Test: Feels remarkably heavy for its size (SG 7.58, like solid lead).",
                "90° Cubic Cleavage: Striking specimen gently breaks it into smaller miniature shiny cubes."
            ],
            careWarnings: [
                "TOXICITY WARNING: Primary lead ore (PbS). Always wash hands thoroughly after handling. Never ingest, grind, or inhale dust.",
                "Keep away from children and pets. Do not clean with acidic chemicals."
            ],
            summary: "The primary ore mineral of lead. Recognized instantly by its intense heft (SG 7.6), mirror-metallic silver luster, and clean 90-degree cubic cleavage.",
            geologicalOrigin: "Hydrothermal veins in limestone (Mississippi Valley-type deposits) and volcanic exhalations.",
            rarityAndOccurrence: "Common; USA (Missouri Tri-State District), Germany (Freiberg), UK (Cumberland)."
        ))

        catalog.append(Mineral(
            name: "Talc",
            alternativeNames: ["Soapstone (massive rock form)", "Steatite", "French Chalk"],
            category: .everydayFinds,
            family: "Phyllosilicates",
            chemicalFormula: "Mg₃Si₄O₁₀(OH)₂",
            crystalSystem: "Monoclinic / Triclinic (massive, foliated, soapy aggregates)",
            mohsHardness: "1.0 (Mohs Baseline)",
            minHardness: 1.0,
            maxHardness: 1.0,
            specificGravity: "2.70 - 2.80",
            luster: "Greasy, pearly, to waxy",
            streak: "White",
            cleavage: "Perfect in 1 direction {001}",
            fracture: "Uneven (soft and easily carved)",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.540 - 1.590",
            colorRange: ["Pale Apple Green", "White", "Silvery Grey", "Cream"],
            commonForms: [.rough, .carved, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Serpentine",
                    visualDifference: "Serpentine is significantly harder (Mohs 3.0 - 5.0) and cannot be scratched by a fingernail.",
                    separatingTest: "Fingernail scratch: Talc (Mohs 1.0) scratches with effortless touch; Serpentine resists fingernail.",
                    hardnessComparison: "Talc 1.0 vs Serpentine 3.5 - 5.0"
                ),
                Lookalike(
                    mineralName: "Gypsum",
                    visualDifference: "Gypsum has a vitreous/silky luster and is slightly harder (Mohs 2.0).",
                    separatingTest: "Tactile feel: Talc feels unmistakably slippery and soapy to the fingers; Gypsum feels smooth but dry.",
                    hardnessComparison: "Talc 1.0 vs Gypsum 2.0"
                ),
                Lookalike(
                    mineralName: "Pyrophyllite",
                    visualDifference: "Pyrophyllite forms radiating stars of blades, but requires chemical analysis to separate from talc without lab testing.",
                    separatingTest: "Chemical test: Talc contains magnesium (Mg); pyrophyllite contains aluminum (Al).",
                    hardnessComparison: "Both Mohs 1.0 - 1.5"
                )
            ],
            ruleOutTests: [
                "Soapy Touch Feel: Rub surface with dry fingertips; feels unmistakably greasy and slippery like a bar of dry soap.",
                "Mohs 1.0 Scratch: Scratches easily with light stroke of a human fingernail (Mohs 2.5) producing soft white talcum powder."
            ],
            careWarnings: [
                "Extremely soft (Mohs 1): scratches from virtually any contact. Protect in padded display.",
                "Do not inhale fine airborne powder particles during carving."
            ],
            summary: "The standard for Mohs Hardness 1.0. A hydrous magnesium sheet silicate known for its remarkably slippery, soapy texture and ease of carving.",
            geologicalOrigin: "Hydrothermal alteration of ultramafic magnesium rocks (dunites/peridotites) and dolomites.",
            rarityAndOccurrence: "Common; Italy (Piedmont), USA (Montana, Vermont), China, France."
        ))

        catalog.append(Mineral(
            name: "Feldspar",
            alternativeNames: ["Orthoclase", "Plagioclase", "Potassium Feldspar", "Microcline"],
            category: .everydayFinds,
            family: "Tectosilicates (Feldspar Group)",
            chemicalFormula: "KAlSi₃O₈ (Orthoclase) to NaAlSi₃O₈ - CaAl₂Si₂O₈ (Plagioclase)",
            crystalSystem: "Monoclinic / Triclinic",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.55 - 2.76",
            luster: "Vitreous to pearly on cleavages",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at or near 90° (Orthoclase 90°, Plagioclase 86°)",
            fracture: "Uneven to conchoidal",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.520 - 1.580",
            colorRange: ["Salmon Pink", "Flesh Red", "White", "Cream", "Grey", "Green (Amazonite)"],
            commonForms: [.rough, .tumbled, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Quartz",
                    visualDifference: "Quartz has conchoidal fracture and lacks two planar 90° cleavage faces.",
                    separatingTest: "Cleavage check & Hardness: Feldspar shows flat reflective cleavage steps at ~90°; Quartz is harder (Mohs 7.0) and has no flat cleavage planes.",
                    hardnessComparison: "Feldspar 6.0 vs Quartz 7.0"
                ),
                Lookalike(
                    mineralName: "Calcite",
                    visualDifference: "Calcite has rhombohedral cleavage at 75° and fizzes in acid.",
                    separatingTest: "Hardness & Acid: Feldspar is Mohs 6 (cannot be scratched by knife); Calcite is Mohs 3 and fizzes in vinegar.",
                    hardnessComparison: "Feldspar 6.0 vs Calcite 3.0"
                ),
                Lookalike(
                    mineralName: "Rhodonite",
                    visualDifference: "Rhodonite is deeper pink with black manganese dendrite veins and higher density (SG 3.6).",
                    separatingTest: "Specific gravity: Rhodonite is noticeably heavier (SG 3.6) than pink orthoclase feldspar (SG 2.56).",
                    hardnessComparison: "Feldspar 6.0 vs Rhodonite 5.5 - 6.5"
                )
            ],
            ruleOutTests: [
                "Two-Direction 90° Cleavage: Turn specimen in light; two flat reflective stair-step planes flash at right angles.",
                "Hardness: Scratches window glass (Mohs 5.5); scratched by quartz (Mohs 7.0)."
            ],
            careWarnings: [
                "Durable for jewelry, but cleavage planes can split if struck sharply against hard surfaces.",
                "Safe for water washing."
            ],
            summary: "The most abundant mineral group in Earth's continental crust (over 50%). Orthoclase serves as the defining standard for Mohs Hardness 6.0.",
            geologicalOrigin: "Primary constituent of igneous granite, pegmatites, and metamorphic gneisses.",
            rarityAndOccurrence: "Most abundant crustal mineral; Norway, Madagascar, USA (Maine, Colorado), Italy."
        ))

        catalog.append(Mineral(
            name: "Olivine",
            alternativeNames: ["Peridot (gem variety)", "Chrysolite", "Dunite rock"],
            category: .everydayFinds,
            family: "Nesosilicates",
            chemicalFormula: "(Mg,Fe)₂SiO₄",
            crystalSystem: "Orthorhombic (prismatic crystals or granular sandy aggregates)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "3.27 - 4.37 (increases with iron)",
            luster: "Vitreous to oily/greasy",
            streak: "White / Colorless",
            cleavage: "Poor / Indistinct in 2 directions",
            fracture: "Conchoidal (brittle)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.654 - 1.690",
            colorRange: ["Olive Green", "Lime Green", "Yellow-Green", "Brownish-Green"],
            commonForms: [.rough, .cut, .tumbled, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Green Tourmaline (Verdelite)",
                    visualDifference: "Tourmaline forms triangular prismatic crystals and has higher hardness (7.5).",
                    separatingTest: "Crystal shape & pleochroism: Tourmaline shows strong dark/light pleochroism; Peridot is singly consistent olive green.",
                    hardnessComparison: "Olivine 6.5 - 7.0 vs Tourmaline 7.0 - 7.5"
                ),
                Lookalike(
                    mineralName: "Epidote",
                    visualDifference: "Epidote is darker pistachio/yellowish-green with perfect basal cleavage and higher refractive index.",
                    separatingTest: "Cleavage check: Epidote has 1 perfect cleavage direction; Olivine has conchoidal fracture.",
                    hardnessComparison: "Both Mohs 6.5"
                ),
                Lookalike(
                    mineralName: "Moldavite (Tektite Glass)",
                    visualDifference: "Moldavite has scaly sculpted melted glass texture with round gas bubbles.",
                    separatingTest: "Refractive index: Moldavite RI is 1.48 - 1.50; Peridot RI is 1.65 - 1.69.",
                    hardnessComparison: "Olivine 6.5 - 7.0 vs Moldavite 5.5"
                )
            ],
            ruleOutTests: [
                "Strong Double Refraction: Look through faceted gemstone at pavilion facet junctions; edges show double lines.",
                "Granular basalt nodules: Look for crumbly sugar-like clusters of translucent green grains inside black volcanic basalt."
            ],
            careWarnings: [
                "Sensitive to rapid temperature changes (thermal shock) and strong acids.",
                "Do not use steam or ultrasonic cleaners on gem peridot."
            ],
            summary: "A magnesium iron silicate that makes up much of Earth's upper mantle and extraterrestrial pallasite meteorites. Gem-quality olive green specimens are called Peridot.",
            geologicalOrigin: "Deep mantle peridotites brought up in kimberlites and basalt lavas; pallasite meteorites.",
            rarityAndOccurrence: "Common in volcanic mantle xenoliths; gem peridot from USA (San Carlos, AZ), Pakistan, Egypt (Zabargad)."
        ))

        catalog.append(Mineral(
            name: "Halite",
            alternativeNames: ["Rock Salt", "Sodium Chloride", "Himalayan Pink Salt"],
            category: .everydayFinds,
            family: "Halides",
            chemicalFormula: "NaCl",
            crystalSystem: "Isometric (perfect cubic crystals and hopper crystals)",
            mohsHardness: "2.0 - 2.5",
            minHardness: 2.0,
            maxHardness: 2.5,
            specificGravity: "2.16 - 2.17",
            luster: "Vitreous to greasy",
            streak: "White",
            cleavage: "Perfect cubic in 3 directions at 90° {001}",
            fracture: "Conchoidal (rarely seen due to easy cubic cleavage)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.544",
            colorRange: ["Colorless", "White", "Pink / Orange (algae/iron inclusions)", "Deep Royal Blue (radiation defects)"],
            commonForms: [.rough, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Sylvite (KCl)",
                    visualDifference: "Sylvite has a bitter, sharp pungent saline taste and stains flame violet.",
                    separatingTest: "Taste & Flame test: Sylvite tastes distinctly bitter; Halite tastes purely salty.",
                    hardnessComparison: "Halite 2.5 vs Sylvite 2.0"
                ),
                Lookalike(
                    mineralName: "Fluorite",
                    visualDifference: "Fluorite does not dissolve in water, is harder (Mohs 4), and has octahedral cleavage.",
                    separatingTest: "Water solubility & Hardness: Halite dissolves quickly in cold water; Fluorite is insoluble.",
                    hardnessComparison: "Halite 2.5 vs Fluorite 4.0"
                ),
                Lookalike(
                    mineralName: "Calcite",
                    visualDifference: "Calcite has 75° rhombohedral cleavage, fizzes in acid, and is insoluble in water.",
                    separatingTest: "Cleavage angle: Halite cleaves at exact 90° right angles; Calcite cleaves at 75° rhombs.",
                    hardnessComparison: "Halite 2.5 vs Calcite 3.0"
                )
            ],
            ruleOutTests: [
                "Water Solubility Test: Place a single tiny grain in a drop of water; dissolves completely within 10 seconds.",
                "90° Cubic Cleavage: Cleaves effortlessly into perfect 90° box-like cubes."
            ],
            careWarnings: [
                "CRITICAL: Keep 100% dry. Rapidly dissolves in water and melts in high atmospheric humidity (deliquescent).",
                "Store with moisture-absorbing desiccant."
            ],
            summary: "Natural rock salt (NaCl). Forms iconic hopper cubes and evaporates from ancient seas. Instantly recognizable by its clean 90° cubic cleavage and pure salty taste.",
            geologicalOrigin: "Sedimentary evaporite salt beds, salt domes, and playas.",
            rarityAndOccurrence: "Abundant; Poland (Wieliczka), Pakistan (Khewra Pink Salt), USA (Utah, Texas, New York)."
        ))

        catalog.append(Mineral(
            name: "Graphite",
            alternativeNames: ["Black Lead", "Plumbago"],
            category: .everydayFinds,
            family: "Native Elements (Carbon)",
            chemicalFormula: "C (Hexagonal sheet polymorph of Carbon)",
            crystalSystem: "Hexagonal (tabular hexagonal crystals, foliated/earthy masses)",
            mohsHardness: "1.0 - 2.0",
            minHardness: 1.0,
            maxHardness: 2.0,
            specificGravity: "2.09 - 2.23",
            luster: "Metallic to dull earthy",
            streak: "Black to dark shiny grey",
            cleavage: "Perfect basal in 1 direction {0001}",
            fracture: "Flaky to uneven; sectile",
            transparency: "Opaque",
            refractiveIndex: "N/A",
            colorRange: ["Iron Black", "Steel Grey"],
            commonForms: [.rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Molybdenite (MoS₂)",
                    visualDifference: "Molybdenite has a subtle bluish cast and leaves a greenish-grey streak on glazed porcelain.",
                    separatingTest: "Streak test: Molybdenite leaves a greenish tinge on porcelain; Graphite leaves a neutral grey-black mark.",
                    hardnessComparison: "Both Mohs 1.0 - 1.5",
                    diagnosticReaction: "Molybdenite decomposes in hot nitric acid; Graphite is inert."
                ),
                Lookalike(
                    mineralName: "Galena",
                    visualDifference: "Galena is much heavier (SG 7.6) and breaks into 90° shiny cubes.",
                    separatingTest: "Heft & Cleavage: Galena is over 3x heavier than graphite of equal size.",
                    hardnessComparison: "Graphite 1.5 vs Galena 2.5"
                ),
                Lookalike(
                    mineralName: "Hematite (Specular)",
                    visualDifference: "Hematite is hard (Mohs 6) and leaves a blood red streak.",
                    separatingTest: "Streak test: Hematite leaves red streak and does not write on paper.",
                    hardnessComparison: "Graphite 1.5 vs Hematite 6.0"
                )
            ],
            ruleOutTests: [
                "Paper Writing Test: Rub specimen gently across plain white printer paper; leaves a clean dark pencil line.",
                "Electrical Conductivity: Excellent conductor of electricity (causes multimeter continuity beep)."
            ],
            careWarnings: [
                "Soils hands and clothing with black carbon smudges on contact.",
                "Extremely soft; keep in separate specimen box."
            ],
            summary: "A pure carbon native element sharing the exact same chemistry as diamond, but organized in weakly bonded graphene sheets that slip easily to write pencil marks.",
            geologicalOrigin: "Regional metamorphism of carbon-rich sedimentary rocks (coal/carbonaceous shale).",
            rarityAndOccurrence: "Common; Sri Lanka, Madagascar, China, USA, Canada."
        ))

        catalog.append(Mineral(
            name: "Dolomite",
            alternativeNames: ["Dolomite Spar", "Pearl Spar"],
            category: .everydayFinds,
            family: "Carbonates",
            chemicalFormula: "CaMg(CO₃)₂",
            crystalSystem: "Trigonal (characteristic saddle-shaped curved rhombohedrons)",
            mohsHardness: "3.5 - 4.0",
            minHardness: 3.5,
            maxHardness: 4.0,
            specificGravity: "2.84 - 2.86",
            luster: "Vitreous to pearly",
            streak: "White",
            cleavage: "Perfect rhombohedral in 3 directions at ~73°",
            fracture: "Subconchoidal",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.500 - 1.681",
            colorRange: ["White", "Flesh Pink", "Cream", "Pale Grey", "Tan"],
            commonForms: [.rough, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Calcite",
                    visualDifference: "Calcite crystal faces are flat and straight, not curved or saddle-shaped.",
                    separatingTest: "Cold Acid Test: Calcite fizzes instantly in cold dilute vinegar; Dolomite only fizzes when heated or powdered into fine dust.",
                    hardnessComparison: "Dolomite (Mohs 3.5 - 4.0) scratches Calcite (Mohs 3.0)."
                ),
                Lookalike(
                    mineralName: "Magnesite",
                    visualDifference: "Magnesite forms chalky porcelain nodules and does not show saddle rhombs.",
                    separatingTest: "Crystal habit: Saddle-shaped curved rhombic crystal faces identify dolomite.",
                    hardnessComparison: "Dolomite 3.5 - 4.0 vs Magnesite 4.0 - 4.5"
                ),
                Lookalike(
                    mineralName: "Ankerite",
                    visualDifference: "Ankerite contains iron (Fe) which weathers to a distinct rusty brown surface patina.",
                    separatingTest: "Weathering tarnish: Ankerite turns brown in air; Dolomite remains white/pink.",
                    hardnessComparison: "Both Mohs 3.5 - 4.0"
                )
            ],
            ruleOutTests: [
                "Saddle-Shaped Crystal Faces: Curved, warped rhombic crystal planes that flash light unevenly.",
                "Powdered Acid Test: Solid chunk does not react with cold vinegar; scratch into fine powder and drop vinegar to see slow bubbling."
            ],
            careWarnings: [
                "Keep away from strong acids which slowly dissolve carbonate bonds.",
                "Safe for water immersion and standard cleaning."
            ],
            summary: "A calcium magnesium carbonate famous for its curved saddle-shaped crystal faces, pearly luster ('pearl spar'), and slower acid reaction compared to calcite.",
            geologicalOrigin: "Dolomitization of sedimentary limestone via magnesium-rich groundwater.",
            rarityAndOccurrence: "Abundant; Italian Alps (Dolomite Mountains), Spain (Eugui), USA (Missouri, Oklahoma)."
        ))

        // ==========================================
        // 3. COLLECTOR STAPLES (16)
        // ==========================================
        catalog.append(Mineral(
            name: "Malachite",
            alternativeNames: ["Green Copper Carbonate"],
            category: .collectorStaples,
            family: "Carbonates",
            chemicalFormula: "Cu₂CO₃(OH)₂",
            crystalSystem: "Monoclinic (botryoidal bubbly masses with concentric banding, acicular sprays)",
            mohsHardness: "3.5 - 4.0",
            minHardness: 3.5,
            maxHardness: 4.0,
            specificGravity: "3.60 - 4.05",
            luster: "Silky (fibrous) to adamantine / dull",
            streak: "Pale Green",
            cleavage: "Perfect in 1 direction (rarely seen due to botryoidal habit)",
            fracture: "Subconchoidal to splintery",
            transparency: "Opaque (translucent in micro-crystals)",
            refractiveIndex: "1.655 - 1.909",
            colorRange: ["Vibrant Emerald Green", "Forest Green", "Banded Dark & Mint Green"],
            commonForms: [.tumbled, .cabochon, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Chrysocolla",
                    visualDifference: "Chrysocolla is cyan/turquoise blue-green with softer waxy luster and no fine dark green concentric rings.",
                    separatingTest: "Specific gravity & Banding: Malachite is heavy (SG 4.0) with concentric dark green ring bands; Chrysocolla is lighter (SG 2.2).",
                    hardnessComparison: "Malachite 3.5 - 4.0 vs Chrysocolla 2.0 - 4.0"
                ),
                Lookalike(
                    mineralName: "Synthetic / Polymer Clay Malachite",
                    visualDifference: "Imitation polymer malachite has sharp black lines instead of subtle natural gradient shades of green.",
                    separatingTest: "Thermal needle test: Hot pin melts polymer imitation with plastic smell; natural malachite is unaffected.",
                    hardnessComparison: "Natural Malachite SG is ~4.0; polymer is ~1.3 (feels like light plastic)."
                ),
                Lookalike(
                    mineralName: "Pseudomalachite",
                    visualDifference: "Pseudomalachite is a copper phosphate with darker blue-green tones and higher hardness (4.5 - 5.0).",
                    separatingTest: "Acid reaction: Malachite effervesces in dilute acid; Pseudomalachite dissolves without bubbling.",
                    hardnessComparison: "Malachite 3.5 - 4.0 vs Pseudomalachite 4.5 - 5.0"
                )
            ],
            ruleOutTests: [
                "Banded Concentric Rings: Swirling eyes and bands of alternating light and dark green.",
                "Heavy Specific Gravity: Feels dense in the palm (SG ~4.0) due to 57% copper content.",
                "Pale Green Streak: Rubbing on streak plate produces light green powder."
            ],
            careWarnings: [
                "TOXICITY IN DUST: Contains high copper (Cu). Never dry-grind, sand, or inhale malachite dust.",
                "Do not soak in water or expose to acids/vinegar (dissolves copper carbonate and ruins polish)."
            ],
            summary: "A prized secondary copper carbonate celebrated for its vibrant emerald green concentric bands, fibrous chatoyancy, and botryoidal formations.",
            geologicalOrigin: "Supergene oxidation zone of primary copper sulfide ore deposits.",
            rarityAndOccurrence: "Common in copper districts; DR Congo (Katanga), Russia (Urals), Arizona, Namibia."
        ))

        catalog.append(Mineral(
            name: "Azurite",
            alternativeNames: ["Chessylite", "Blue Malachite Ore"],
            category: .collectorStaples,
            family: "Carbonates",
            chemicalFormula: "Cu₃(CO₃)₂(OH)₂",
            crystalSystem: "Monoclinic (tabular crystals, radiating rosettes, azure crusts)",
            mohsHardness: "3.5 - 4.0",
            minHardness: 3.5,
            maxHardness: 4.0,
            specificGravity: "3.77 - 3.89",
            luster: "Vitreous to adamantine",
            streak: "Light Sky Blue",
            cleavage: "Perfect in 1 direction {011}",
            fracture: "Conchoidal",
            transparency: "Transparent to Translucent (deep crystals appear opaque)",
            refractiveIndex: "1.730 - 1.838",
            colorRange: ["Intense Azure Blue", "Deep Indigo", "Cobalt Blue", "Midnight Blue"],
            commonForms: [.rough, .cabochon, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Lapis Lazuli",
                    visualDifference: "Lapis Lazuli is a rock aggregate containing golden pyrite flecks and white calcite veins, not deep crystalline azure.",
                    separatingTest: "Hardness & streak: Lapis is harder (Mohs 5.0 - 5.5); Azurite is Mohs 3.5 and effervesces in acid.",
                    hardnessComparison: "Azurite 3.5 vs Lapis Lazuli 5.5"
                ),
                Lookalike(
                    mineralName: "Sodalite",
                    visualDifference: "Sodalite has royal blue color with white nepheline streaks and no association with green malachite.",
                    separatingTest: "Hardness: Sodalite (Mohs 5.5 - 6.0) is not scratched by copper coin; Azurite is easily scratched.",
                    hardnessComparison: "Azurite 3.5 vs Sodalite 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Linarite",
                    visualDifference: "Linarite is a lead-copper sulfate with similar blue but leaves a pale blue streak and contains lead.",
                    separatingTest: "Streak and crystal habit: Linarite forms elongated tabular blades.",
                    hardnessComparison: "Azurite 3.5 vs Linarite 2.5"
                )
            ],
            ruleOutTests: [
                "Electric Royal Blue Streak: Leaves a soft sky-blue mark on ceramic streak plate.",
                "Malachite Association: Often intergrown with green malachite ('azurmalachite')."
            ],
            careWarnings: [
                "Over time, exposure to atmospheric humidity slowly alters azurite into green malachite.",
                "Do not clean with hot water, steam, or household chemical detergents."
            ],
            summary: "An iconic copper carbonate famous for its mesmerizing royal azure-blue crystals. Renowned since antiquity as a painter's pigment and collector centerpiece.",
            geologicalOrigin: "Supergene oxidation zones of copper deposits where carbonate is abundant.",
            rarityAndOccurrence: "Famous deposits in France (Chessy), Morocco (Touissit), USA (Bisbee, AZ), Namibia (Tsumeb)."
        ))

        catalog.append(Mineral(
            name: "Tourmaline",
            alternativeNames: ["Schorl (Black)", "Elbaite (Watermelon/Pink/Green)", "Dravite (Brown)", "Indicolite (Blue)"],
            category: .collectorStaples,
            family: "Cyclosilicates (Complex Borosilicates)",
            chemicalFormula: "(Na,Ca)(Li,Mg,Al,Fe)₃Al₆(BO₃)₃Si₆O₁₈(OH)₄",
            crystalSystem: "Trigonal (elongated 3-sided rounded triangular prisms with vertical striations)",
            mohsHardness: "7.0 - 7.5",
            minHardness: 7.0,
            maxHardness: 7.5,
            specificGravity: "3.03 - 3.26",
            luster: "Vitreous to resinous",
            streak: "White",
            cleavage: "None (indistinct)",
            fracture: "Uneven to conchoidal (brittle cross-fractures)",
            transparency: "Transparent to Opaque",
            refractiveIndex: "1.614 - 1.666",
            colorRange: ["Jet Black (Schorl)", "Watermelon (Pink core/Green rim)", "Emerald Green", "Hot Pink (Rubellite)", "Neon Blue (Paraiba)"],
            commonForms: [.rough, .cut, .tumbled, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Black Obsidian",
                    visualDifference: "Obsidian has smooth glassy conchoidal surfaces with no 3-sided prismatic crystal shape.",
                    separatingTest: "Hardness test: Obsidian is Mohs 5.0 - 5.5; Black tourmaline is Mohs 7.0 - 7.5 and scratches glass easily.",
                    hardnessComparison: "Tourmaline 7.5 vs Obsidian 5.0"
                ),
                Lookalike(
                    mineralName: "Epidote",
                    visualDifference: "Epidote has yellowish-pistachio color and 1 perfect cleavage plane.",
                    separatingTest: "Crystal cross-section: Tourmaline has rounded triangular cross-sections; Epidote is monoclinic prismatic.",
                    hardnessComparison: "Tourmaline 7.5 vs Epidote 6.5"
                ),
                Lookalike(
                    mineralName: "Emerald (Green Beryl)",
                    visualDifference: "Emerald has 6-sided hexagonal prisms; Green tourmaline has 3-sided rounded triangular prisms.",
                    separatingTest: "Pleochroism: Green tourmaline shows dramatic dark olive-to-light green pleochroism when rotated in polarized light.",
                    hardnessComparison: "Tourmaline 7.0 - 7.5 vs Emerald 7.5 - 8.0"
                )
            ],
            ruleOutTests: [
                "Triangular Rounded Cross-Section: Inspect crystal end; cross-section forms a distinctive 3-sided spherical triangle.",
                "Vertical Striations: Deep parallel grooves running the entire lengthwise span of the prism faces.",
                "Pyroelectricity: Rubbing briskly with a microfiber cloth attracts tiny scraps of paper via electrostatic charge."
            ],
            careWarnings: [
                "Hard and durable for jewelry, but internal inclusions can make some crystals vulnerable to hard impacts.",
                "Safe for water and mild soapy cleaning; avoid steam cleaning included specimens."
            ],
            summary: "A complex boron cyclosilicate renowned for having the widest color spectrum of any gemstone family, striking 3-sided triangular prisms, and pyroelectric static charging.",
            geologicalOrigin: "Granitic pegmatite pockets, pneumatolytic veins, and metamorphic schists.",
            rarityAndOccurrence: "Widespread; Brazil (Minas Gerais), Afghanistan, Madagascar, California, Maine."
        ))

        catalog.append(Mineral(
            name: "Garnet",
            alternativeNames: ["Almandine", "Pyrope", "Spessartine", "Grossular (Tsavorite)", "Andradite (Demantoid)"],
            category: .collectorStaples,
            family: "Nesosilicates (Garnet Group)",
            chemicalFormula: "(Fe,Mg,Ca,Mn)₃(Al,Fe,Cr)₂(SiO₄)₃",
            crystalSystem: "Isometric (dodecahedrons [12 faces] and trapezohedrons [24 faces])",
            mohsHardness: "6.5 - 7.5",
            minHardness: 6.5,
            maxHardness: 7.5,
            specificGravity: "3.56 - 4.32",
            luster: "Vitreous to resinous",
            streak: "White",
            cleavage: "None (parting on {110})",
            fracture: "Conchoidal to uneven",
            transparency: "Transparent to Opaque",
            refractiveIndex: "1.720 - 1.890 (High brilliance, singly refractive)",
            colorRange: ["Deep Wine Red", "Burgundy", "Fiery Orange (Spessartine)", "Vivid Green (Tsavorite)", "Honey Yellow"],
            commonForms: [.rough, .cut, .tumbled, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Ruby (Corundum)",
                    visualDifference: "Ruby forms 6-sided hexagonal barrels, shows strong red fluorescence under UV, and is doubly refractive.",
                    separatingTest: "Hardness & Optic Character: Ruby (Mohs 9) is doubly refractive and scratches garnet (Mohs 7.5); Garnet is singly refractive (isotropic).",
                    hardnessComparison: "Garnet 7.5 vs Ruby 9.0"
                ),
                Lookalike(
                    mineralName: "Spinel",
                    visualDifference: "Spinel forms 8-sided octahedrons rather than 12-sided dodecahedrons.",
                    separatingTest: "Crystal habit: Garnet forms dodecahedrons/trapezohedrons; Spinel forms octahedral pyramids.",
                    hardnessComparison: "Garnet 7.5 vs Spinel 8.0"
                ),
                Lookalike(
                    mineralName: "Zircon",
                    visualDifference: "Zircon is strongly doubly refractive (facet doubling visible under 10x loupe).",
                    separatingTest: "Polariscope / Doubling: Garnet is isotropic (zero facet doubling); Zircon shows extreme double edges.",
                    hardnessComparison: "Garnet 7.5 vs Zircon 7.5"
                )
            ],
            ruleOutTests: [
                "12-Sided Dodecahedron Habit: Natural crystals form symmetrical soccer-ball-like 12-sided rhombic dodecahedron spheres.",
                "Isotropic Polariscope Reaction: Stays dark (extinction) under cross-polarized light throughout 360° rotation."
            ],
            careWarnings: [
                "Tough and highly durable with no cleavage; ideal for daily jewelry wear.",
                "Safe for water and ultrasonic cleaning (unless heavily fractured)."
            ],
            summary: "A family of complex silicate gemstones famous for their rich deep red wine colors, iconic 12-sided dodecahedron crystals, high brilliance, and lack of cleavage.",
            geologicalOrigin: "Regional metamorphic schists, gneisses, and contact skarns.",
            rarityAndOccurrence: "Abundant; India, Sri Lanka, Madagascar, USA (New York, Idaho), Tanzania."
        ))

        catalog.append(Mineral(
            name: "Beryl",
            alternativeNames: ["Aquamarine (Blue)", "Emerald (Green)", "Morganite (Pink)", "Heliodor (Yellow)", "Goshenite (Clear)"],
            category: .collectorStaples,
            family: "Cyclosilicates",
            chemicalFormula: "Be₃Al₂Si₆O₁₈ with trace Cr, V, Fe, Mn",
            crystalSystem: "Hexagonal (distinct 6-sided hexagonal prisms with flat pinacoid terminations)",
            mohsHardness: "7.5 - 8.0",
            minHardness: 7.5,
            maxHardness: 8.0,
            specificGravity: "2.66 - 2.92",
            luster: "Vitreous",
            streak: "White",
            cleavage: "Imperfect / basal in 1 direction {0001}",
            fracture: "Conchoidal to uneven",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.566 - 1.602",
            colorRange: ["Sea Blue (Aquamarine)", "Vivid Emerald Green", "Peach Pink (Morganite)", "Golden Yellow (Heliodor)"],
            commonForms: [.rough, .cut, .tumbled, .cabochon],
            topLookalikes: [
                Lookalike(
                    mineralName: "Blue Topaz",
                    visualDifference: "Blue topaz has a diamond-shaped prism cross section, basal cleavage, and feels denser (SG 3.53).",
                    separatingTest: "Density & Cleavage: Topaz sinks in bromoform (SG 3.53); Aquamarine floats (SG 2.70).",
                    hardnessComparison: "Beryl 7.5 - 8.0 vs Topaz 8.0"
                ),
                Lookalike(
                    mineralName: "Green Tourmaline",
                    visualDifference: "Tourmaline has 3-sided rounded triangular prism faces; Beryl has crisp 6-sided hexagonal prisms.",
                    separatingTest: "Crystal symmetry: Beryl prisms have 6 equal prism faces with 120° angles.",
                    hardnessComparison: "Beryl 7.5 - 8.0 vs Tourmaline 7.0 - 7.5"
                ),
                Lookalike(
                    mineralName: "Apatite",
                    visualDifference: "Apatite shares hexagonal habit but is soft enough to scratch with a pocket knife.",
                    separatingTest: "Hardness test: Beryl (Mohs 7.5 - 8) easily scratches quartz and glass; Apatite (Mohs 5) is scratched by a knife.",
                    hardnessComparison: "Beryl 7.5 - 8.0 vs Apatite 5.0"
                )
            ],
            ruleOutTests: [
                "Hexagonal Prism Symmetry: 6 identical prism faces meeting flat perpendicular end terminations.",
                "Hardness: Scratches quartz (Mohs 7.0) with clean smooth incision."
            ],
            careWarnings: [
                "Emerald variety frequently contains natural fissures ('jardin') and should never be cleaned in ultrasonic or steam cleaners.",
                "Aquamarine and Morganite are durable for daily wear."
            ],
            summary: "A beryllium aluminum cyclosilicate that hosts some of the world's most legendary gemstones: royal green Emerald, ocean-blue Aquamarine, and blush Morganite.",
            geologicalOrigin: "Granite pegmatites, hydrothermal calcite veins, and metamorphic schists.",
            rarityAndOccurrence: "Colombia (Emeralds), Brazil (Minas Gerais Aquamarines), Pakistan, Madagascar."
        ))

        catalog.append(Mineral(
            name: "Corundum",
            alternativeNames: ["Ruby (Red)", "Sapphire (Blue/All other colors)", "Padparadscha"],
            category: .collectorStaples,
            family: "Oxides (Hematite Group)",
            chemicalFormula: "Al₂O₃ with trace Cr³⁺ (Ruby) or Fe²⁺/Ti⁴⁺ (Blue Sapphire)",
            crystalSystem: "Trigonal (hexagonal barrel-shaped bi-pyramids and tabular prisms)",
            mohsHardness: "9.0 (Mohs Baseline)",
            minHardness: 9.0,
            maxHardness: 9.0,
            specificGravity: "3.98 - 4.05",
            luster: "Adamantine to vitreous",
            streak: "White",
            cleavage: "None (rhombohedral and basal parting)",
            fracture: "Conchoidal to uneven",
            transparency: "Transparent to Opaque",
            refractiveIndex: "1.762 - 1.778",
            colorRange: ["Pigeon Blood Red (Ruby)", "Royal Cornflower Blue (Sapphire)", "Padparadscha Pink-Orange", "Yellow", "Star Asterism"],
            commonForms: [.cut, .rough, .cabochon, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Spinel",
                    visualDifference: "Red spinel forms sharp octahedral crystals and is singly refractive (isotropic).",
                    separatingTest: "Refractometer / Polariscope: Spinel RI is 1.718 (singly refractive); Ruby RI is 1.762-1.770 (doubly refractive with pleochroism).",
                    hardnessComparison: "Corundum 9.0 vs Spinel 8.0"
                ),
                Lookalike(
                    mineralName: "Red Garnet",
                    visualDifference: "Garnet is darker, has lower refractive index, and is singly refractive without UV fluorescence.",
                    separatingTest: "Hardness & UV: Corundum (Mohs 9) scratches Topaz and Garnet effortlessly; Rubies glow intense crimson under 365nm UV.",
                    hardnessComparison: "Corundum 9.0 vs Garnet 7.5"
                ),
                Lookalike(
                    mineralName: "Blue Tanzanite",
                    visualDifference: "Tanzanite has trichroism (blue-violet-burgundy) and lower hardness (6.5 - 7.0).",
                    separatingTest: "Hardness test: Sapphire is Mohs 9.0 and cannot be scratched by any mineral other than diamond.",
                    hardnessComparison: "Sapphire 9.0 vs Tanzanite 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Mohs 9.0 Scratch Benchmark: Effortlessly scratches Topaz (8.0), Quartz (7.0), and all glass with zero wear on point.",
                "Red UV Fluorescence (Ruby): Intense neon red glow under longwave UV due to Cr³⁺ ions."
            ],
            careWarnings: [
                "Extremely durable (second hardest natural mineral). Safe for all jewelry cleaning methods.",
                "Fracture-filled or oiled stones should avoid steam and acid."
            ],
            summary: "Pure crystalline aluminum oxide (Al₂O₃) defining Mohs Hardness 9.0. Red specimens are Ruby; all other colors (blue, yellow, pink, green) are Sapphire.",
            geologicalOrigin: "Metamorphic marbles, basalts, and alluvial gem gravel placers.",
            rarityAndOccurrence: "Myanmar (Mogok Rubies), Sri Lanka (Ceylon Sapphires), Madagascar, Kashmir, Montana."
        ))

        catalog.append(Mineral(
            name: "Topaz",
            alternativeNames: ["Imperial Topaz", "Precious Topaz", "Blue Topaz"],
            category: .collectorStaples,
            family: "Nesosilicates",
            chemicalFormula: "Al₂SiO₄(F,OH)₂",
            crystalSystem: "Orthorhombic (prismatic crystals with diamond-shaped cross-section and steep roof terminations)",
            mohsHardness: "8.0 (Mohs Baseline)",
            minHardness: 8.0,
            maxHardness: 8.0,
            specificGravity: "3.49 - 3.57",
            luster: "Vitreous",
            streak: "White",
            cleavage: "Perfect basal in 1 direction {001}",
            fracture: "Subconchoidal to uneven",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.606 - 1.638",
            colorRange: ["Imperial Golden Orange", "Sherry Red", "Sky Blue", "Colorless", "Pink"],
            commonForms: [.cut, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Citrine (Quartz)",
                    visualDifference: "Citrine has hexagonal prisms, lower heft, and no basal cleavage.",
                    separatingTest: "Hardness & Specific Gravity: Topaz (Mohs 8, SG 3.53) scratches Quartz (Mohs 7, SG 2.65) and feels significantly heavier.",
                    hardnessComparison: "Topaz 8.0 vs Citrine 7.0"
                ),
                Lookalike(
                    mineralName: "Aquamarine (Beryl)",
                    visualDifference: "Aquamarine has hexagonal prisms and lower specific gravity (2.70).",
                    separatingTest: "Cleavage check: Topaz has perfect 1-way basal cleavage (splits flat across prism base); Beryl has poor cleavage.",
                    hardnessComparison: "Topaz 8.0 vs Beryl 7.5 - 8.0"
                ),
                Lookalike(
                    mineralName: "Danburite",
                    visualDifference: "Danburite has diamond-shaped prisms but lower hardness (7.0 - 7.5) and lower SG (3.00).",
                    separatingTest: "Hardness test: Topaz scratches Danburite.",
                    hardnessComparison: "Topaz 8.0 vs Danburite 7.0 - 7.5"
                )
            ],
            ruleOutTests: [
                "Mohs 8.0 Scratch Benchmark: Scratches quartz (7.0) cleanly; cannot scratch corundum (9.0).",
                "Diamond-Shaped Prism Cross-Section: 8-sided orthorhombic prism with 4 dominant faces forming a diamond shape.",
                "Basal Cleavage Step: Flat mirror-like reflective break perpendicular to the long crystal axis."
            ],
            careWarnings: [
                "Perfect basal cleavage makes topaz susceptible to chipping or splitting if struck on hard surfaces.",
                "Avoid thermal shock and ultrasonic cleaning."
            ],
            summary: "The defining mineral for Mohs Hardness 8.0. An aluminum fluorosilicate prized for its high clarity, high refractive index, and vivid golden-orange 'Imperial' varieties.",
            geologicalOrigin: "High-temperature fluorine vapors in granitic pegmatites and rhyolitic lava cavities.",
            rarityAndOccurrence: "Brazil (Ouro Preto Imperial Topaz), Pakistan, Russia (Urals), USA (Utah Topaz Mountain)."
        ))

        catalog.append(Mineral(
            name: "Spinel",
            alternativeNames: ["Balas Ruby (historical misnomer)", "Noble Spinel"],
            category: .collectorStaples,
            family: "Oxides (Spinel Group)",
            chemicalFormula: "MgAl₂O₄",
            crystalSystem: "Isometric (sharp 8-sided octahedrons and flattened macle twins)",
            mohsHardness: "8.0",
            minHardness: 8.0,
            maxHardness: 8.0,
            specificGravity: "3.58 - 3.61",
            luster: "Vitreous to subadamantine",
            streak: "White",
            cleavage: "None (indistinct octahedral parting)",
            fracture: "Conchoidal",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.712 - 1.720 (Singly Refractive)",
            colorRange: ["Vibrant Flame Red", "Cobalt Blue", "Hot Pink", "Violet", "Black (Pleonaste)"],
            commonForms: [.cut, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Ruby (Corundum)",
                    visualDifference: "Ruby forms 6-sided hexagonal barrels, is doubly refractive, and historically was confused with spinel (e.g., the Black Prince's Ruby).",
                    separatingTest: "Polariscope test: Spinel is isotropic (singly refractive); Ruby is anisotropic (doubly refractive with dichroism).",
                    hardnessComparison: "Spinel 8.0 vs Corundum 9.0"
                ),
                Lookalike(
                    mineralName: "Red Garnet",
                    visualDifference: "Garnet forms 12-sided dodecahedrons; Spinel forms 8-sided octahedrons.",
                    separatingTest: "Refractive Index: Spinel RI is 1.718; Garnet RI is higher (1.76 - 1.81).",
                    hardnessComparison: "Spinel 8.0 vs Garnet 7.0 - 7.5"
                ),
                Lookalike(
                    mineralName: "Sapphire",
                    visualDifference: "Blue sapphire is doubly refractive with strong blue/green pleochroism.",
                    separatingTest: "Dichroscope inspection: Cobalt spinel shows zero color change under dichroscope.",
                    hardnessComparison: "Spinel 8.0 vs Sapphire 9.0"
                )
            ],
            ruleOutTests: [
                "Octahedral Crystal Geometry: Natural crystals form perfect 8-sided double pyramids (octahedrons).",
                "Single Refraction Isotropic Check: Completely dark under 360° rotation between crossed polarizers."
            ],
            careWarnings: [
                "Extremely tough and durable with no cleavage planes; ideal for daily jewelry rings.",
                "Safe for water, steam, and ultrasonic cleaning."
            ],
            summary: "A magnesium aluminum oxide famous for its high brilliance and historical role as the 'great impostor' in royal crown jewels (like the Black Prince's Ruby in the British Imperial Crown).",
            geologicalOrigin: "Metamorphic contact skarns, dolomitic marbles, and alluvial gem gravels.",
            rarityAndOccurrence: "Myanmar (Mogok), Sri Lanka, Tajikistan (Badakhshan), Vietnam, Tanzania."
        ))

        catalog.append(Mineral(
            name: "Opal",
            alternativeNames: ["Precious Opal", "Black Opal", "Fire Opal", "Boulder Opal"],
            category: .collectorStaples,
            family: "Mineraloids (Hydrated Amorphous Silica)",
            chemicalFormula: "SiO₂·nH₂O (3% to 21% water)",
            crystalSystem: "Amorphous (non-crystalline array of submicroscopic silica spheres)",
            mohsHardness: "5.5 - 6.5",
            minHardness: 5.5,
            maxHardness: 6.5,
            specificGravity: "1.98 - 2.25 (Very Light)",
            luster: "Vitreous, waxy, to resinous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal (fragile)",
            transparency: "Transparent to Opaque",
            refractiveIndex: "1.420 - 1.470",
            colorRange: ["Play-of-Color Spectral Flash (Red, Green, Blue, Orange)", "Black Matrix", "White", "Jelly Orange (Fire Opal)"],
            commonForms: [.cabochon, .rough, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Synthetic Opal (Gilson / Opalite)",
                    visualDifference: "Synthetic opals display a repetitive 'lizard skin' or columnar honeycomb pattern under magnification.",
                    separatingTest: "Magnification test: Look for columnar lizard-skin cellular structure under 20x loupe; natural play-of-color is organic and randomized.",
                    hardnessComparison: "Both Mohs 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Labradorite",
                    visualDifference: "Labradorite has directional grey-blue metallic labradorescence across cleavage planes; Opal flashes floating spectral dots.",
                    separatingTest: "Hardness & Structure: Labradorite is feldspar (Mohs 6 - 6.5) with visible twinning striations; Opal is amorphous mineraloid (SG 2.15).",
                    hardnessComparison: "Opal 5.5 - 6.5 vs Labradorite 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Ammolite (Fossil Shell)",
                    visualDifference: "Ammolite is fossilized aragonite shell with sheet-like mosaic fracture plates and reacts to acid.",
                    separatingTest: "Acid test: Ammolite fizzes with vinegar; Opal is completely inert to acid.",
                    hardnessComparison: "Opal 5.5 - 6.5 vs Ammolite 3.5 - 4.0"
                )
            ],
            ruleOutTests: [
                "Diffraction Play-of-Color: Move light source across stone; points of pure spectral light shift wavelengths organically.",
                "Low Specific Gravity: Exceptionally lightweight in hand (SG ~2.15) due to 3-10% internal water content."
            ],
            careWarnings: [
                "HYDRATION CARE: Contains internal water; avoid extreme dry heat, sudden thermal shock, and direct sunlight which cause 'crazing' (crack networks).",
                "Never clean in ultrasonic cleaners or submerge in household chemical solutions."
            ],
            summary: "A hydrated amorphous silica mineraloid where submicroscopic silica spheres diffract white light into blazing rainbow flashes of 'play-of-color'. Australia's national gemstone.",
            geologicalOrigin: "Low-temperature silica-rich groundwater filling voids and fissures in sedimentary and volcanic rocks.",
            rarityAndOccurrence: "Australia (Lightning Ridge Black Opal, Coober Pedy), Ethiopia (Welo Opal), Mexico (Fire Opal)."
        ))

        catalog.append(Mineral(
            name: "Turquoise",
            alternativeNames: ["Callais", "Robin's Egg Turquoise"],
            category: .collectorStaples,
            family: "Phosphates",
            chemicalFormula: "CuAl₆(PO₄)₄(OH)₈·4H₂O",
            crystalSystem: "Triclinic (massive cryptocrystalline nodules, veinlets, and crusts)",
            mohsHardness: "5.0 - 6.0 (chalky when low grade)",
            minHardness: 5.0,
            maxHardness: 6.0,
            specificGravity: "2.60 - 2.90",
            luster: "Waxy to dull subvitreous",
            streak: "White to pale greenish-blue",
            cleavage: "None in massive forms",
            fracture: "Conchoidal to smooth uneven",
            transparency: "Opaque",
            refractiveIndex: "1.610 - 1.650",
            colorRange: ["Robin's Egg Sky Blue", "Turquoise Blue", "Apple Green", "Teal with Dark Spiderweb Matrix"],
            commonForms: [.cabochon, .rough, .carved, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Dyed Howlite / Magnesite ('Turquenite')",
                    visualDifference: "Dyed howlite shows blue color concentrated in tiny surface cracks; interior is white when scratched or broken.",
                    separatingTest: "Acetone Swab / Hardness: Swab with acetone removes dye from dyed howlite; Howlite is softer (Mohs 3.5) and scratches easily.",
                    hardnessComparison: "Turquoise 5.0 - 6.0 vs Howlite 3.5",
                    diagnosticReaction: "Hot needle or acetone test reveals artificial dye on imitation stones."
                ),
                Lookalike(
                    mineralName: "Variscite",
                    visualDifference: "Variscite is aluminum phosphate that is distinctly leaf green to mint green, lacking sky blue copper tones.",
                    separatingTest: "Hardness & Refractive Index: Variscite is softer (Mohs 4.5) and lower RI (1.57).",
                    hardnessComparison: "Turquoise 5.5 vs Variscite 4.5"
                ),
                Lookalike(
                    mineralName: "Chrysocolla",
                    visualDifference: "Chrysocolla is softer (Mohs 2 - 4), more translucent, and adheres to the tongue when touched.",
                    separatingTest: "Hardness & Porosity: Chrysocolla is scratched by copper coin (Mohs 3.5); natural gem turquoise resists copper penny.",
                    hardnessComparison: "Turquoise 5.5 vs Chrysocolla 2.5 - 3.5"
                )
            ],
            ruleOutTests: [
                "Acetone Q-tip Test: Rub unpolished back with nail polish remover; zero blue color should bleed onto the cotton swab.",
                "Copper Penny Scratch Test: High-grade turquoise (Mohs 5.5 - 6) will NOT be scratched by a pure copper penny."
            ],
            careWarnings: [
                "POROUS: Highly absorbs oils, perfumes, sunscreen, and soaps which turn vivid blue turquoise into dull dull-green.",
                "Clean only with a soft damp cloth. Never submerge in soapy water."
            ],
            summary: "A prized copper aluminum hydrous phosphate sacred to Native American and ancient Persian cultures. Its sky-blue to teal matrix patterns are globally revered.",
            geologicalOrigin: "Supergene weathering of copper-rich aluminous rocks in arid desert regions.",
            rarityAndOccurrence: "USA (Arizona Sleeping Beauty, Nevada), Iran (Nishapur), China (Hubei), Egypt (Sinai)."
        ))

        catalog.append(Mineral(
            name: "Lapis Lazuli",
            alternativeNames: ["Lapis", "Lazurite Rock"],
            category: .collectorStaples,
            family: "Metamorphic Rock (Lazurite + Calcite + Pyrite)",
            chemicalFormula: "(Na,Ca)₈(AlSiO₄)₆(SO₄,S,Cl)₂ (Dominant mineral: Lazurite)",
            crystalSystem: "Isometric (aggregate rock)",
            mohsHardness: "5.0 - 5.5",
            minHardness: 5.0,
            maxHardness: 5.5,
            specificGravity: "2.70 - 2.90",
            luster: "Dull to greasy / vitreous",
            streak: "Light Blue",
            cleavage: "None (massive rock)",
            fracture: "Uneven to granular",
            transparency: "Opaque",
            refractiveIndex: "1.500",
            colorRange: ["Royal Ultramarine Blue", "Deep Indigo", "Gold-flecked Blue", "Denim Blue"],
            commonForms: [.cabochon, .carved, .tumbled, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Sodalite",
                    visualDifference: "Sodalite has royal blue color with white nepheline/calcite patches but lacks metallic gold pyrite specks.",
                    separatingTest: "Pyrite Inclusions & Streak: Natural Lapis Lazuli contains golden metallic brass flecks of pyrite (FeS₂) and leaves a light blue streak; Sodalite streak is white.",
                    hardnessComparison: "Lapis 5.0 - 5.5 vs Sodalite 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Dyed Jasper / 'Swiss Lapis'",
                    visualDifference: "Dyed jasper shows color pooled in fissures and lacks genuine crystalline pyrite flecks.",
                    separatingTest: "Acetone test & Hardness: Swiss lapis is dyed quartz/jasper (Mohs 7) and acetone dissolves dye.",
                    hardnessComparison: "Lapis 5.0 - 5.5 vs Jasper 7.0"
                ),
                Lookalike(
                    mineralName: "Dumortierite Quartz",
                    visualDifference: "Dumortierite is denim blue within hard quartz matrix and has higher hardness (7.0).",
                    separatingTest: "Hardness test: Dumortierite scratches glass easily (Mohs 7); Lapis is softer (Mohs 5.5).",
                    hardnessComparison: "Lapis 5.5 vs Dumortierite 7.0"
                )
            ],
            ruleOutTests: [
                "Pyrite Flecks: Natural brass-metallic golden flecks scattered across royal ultramarine blue background.",
                "Streak: Rubbing on streak plate produces light azure blue streak (not white or gray)."
            ],
            careWarnings: [
                "Contains calcite veins: sensitive to acids, vinegar, hot water, and household cleaning detergents.",
                "Clean gently with dry or slightly damp soft cloth."
            ],
            summary: "A legendary deep-blue metamorphic rock composed of lazurite, sparkling golden pyrite flecks, and white calcite veins. The historical source of ultramarine paint pigment.",
            geologicalOrigin: "Contact metamorphism of limestone/marble by granitic intrusions.",
            rarityAndOccurrence: "Mined for over 6,000 years in Afghanistan (Badakhshan / Sar-e-Sang), Chile (Ovalle), Russia (Lake Baikal)."
        ))

        catalog.append(Mineral(
            name: "Rhodochrosite",
            alternativeNames: ["Inca Rose", "Manganese Carbonate", "Raspberry Spar"],
            category: .collectorStaples,
            family: "Carbonates",
            chemicalFormula: "MnCO₃",
            crystalSystem: "Trigonal (rhombohedral crystals, stalactitic concentric banded masses)",
            mohsHardness: "3.5 - 4.0",
            minHardness: 3.5,
            maxHardness: 4.0,
            specificGravity: "3.50 - 3.70",
            luster: "Vitreous to pearly",
            streak: "White",
            cleavage: "Perfect rhombohedral in 3 directions at 73°",
            fracture: "Uneven to conchoidal",
            transparency: "Transparent (gem crystals) to Translucent (banded)",
            refractiveIndex: "1.597 - 1.816",
            colorRange: ["Raspberry Pink", "Rose Red", "Banded Pink and Cream", "Deep Ruby Red"],
            commonForms: [.rough, .cabochon, .cut, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Rhodonite",
                    visualDifference: "Rhodonite is silicate (Mohs 5.5 - 6.5) with black manganese oxide veins; Rhodochrosite has white/cream bands.",
                    separatingTest: "Hardness & Acid: Rhodochrosite (Mohs 3.5 - 4) is easily scratched by a copper coin and fizzes in warm dilute acid; Rhodonite resists copper coin and does not fizz.",
                    hardnessComparison: "Rhodochrosite 3.5 - 4.0 vs Rhodonite 5.5 - 6.5"
                ),
                Lookalike(
                    mineralName: "Rose Quartz",
                    visualDifference: "Rose quartz is hard (Mohs 7.0), lacks concentric zig-zag bands, and is non-reactive to acid.",
                    separatingTest: "Hardness test: Pocket knife scratches Rhodochrosite easily; Rose Quartz cannot be scratched by steel.",
                    hardnessComparison: "Rhodochrosite 3.5 vs Rose Quartz 7.0"
                ),
                Lookalike(
                    mineralName: "Manganoan Calcite",
                    visualDifference: "Manganoan calcite is paler baby pink and fluoresces blinding hot pink under UV.",
                    separatingTest: "Specific gravity: Rhodochrosite is much denser (SG 3.70) due to manganese; Calcite is SG 2.71.",
                    hardnessComparison: "Rhodochrosite 3.5 - 4.0 vs Calcite 3.0"
                )
            ],
            ruleOutTests: [
                "Banded Zig-Zag Patterns: Concentric pink and white lace bands inside stalactitic cross-sections.",
                "Warm Acid Effervescence: Slow effervescence with warm dilute hydrochloric acid or vinegar."
            ],
            careWarnings: [
                "Soft (Mohs 3.5 - 4) and cleavable: protect from scratches, knocks, and abrasive grit.",
                "Do not expose to acidic solutions which etch and dissolve the polish."
            ],
            summary: "A manganese carbonate gemstone celebrated for its intoxicating raspberry-pink color and white zig-zag bands. Colorado's state mineral and Argentina's national gemstone.",
            geologicalOrigin: "Hydrothermal veins associated with silver, lead, and copper ores; cave stalactites in silver mines.",
            rarityAndOccurrence: "USA (Sweet Home Mine, CO - world's finest crystals), Argentina (Capillitas stalactites), Peru, South Africa."
        ))

        catalog.append(Mineral(
            name: "Rhodonite",
            alternativeNames: ["Manganese Silicate", "Pink Tourmaline lookalike"],
            category: .collectorStaples,
            family: "Inosilicates (Pyroxenoid Group)",
            chemicalFormula: "(Mn,Fe,Mg,Ca)SiO₃",
            crystalSystem: "Triclinic (tabular crystals, massive compact granular aggregates)",
            mohsHardness: "5.5 - 6.5",
            minHardness: 5.5,
            maxHardness: 6.5,
            specificGravity: "3.57 - 3.76",
            luster: "Vitreous to pearly on cleavage faces",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at 92.5°",
            fracture: "Conchoidal to uneven; very tough",
            transparency: "Translucent to Opaque (rarely transparent gem crystals)",
            refractiveIndex: "1.716 - 1.752",
            colorRange: ["Dusty Rose Pink", "Flesh Red", "Brownish Pink with Black Manganese Oxide Veins"],
            commonForms: [.cabochon, .rough, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Rhodochrosite",
                    visualDifference: "Rhodochrosite has white/cream concentric bands; Rhodonite has distinctive black web-like dendrite veins.",
                    separatingTest: "Hardness test: Pocket knife (Mohs 5.5) will NOT scratch Rhodonite (Mohs 6.0); Rhodochrosite is easily scratched (Mohs 3.5).",
                    hardnessComparison: "Rhodonite 6.0 vs Rhodochrosite 3.5"
                ),
                Lookalike(
                    mineralName: "Pink Feldspar (Orthoclase)",
                    visualDifference: "Pink feldspar is salmon-peach rather than rose-pink and lacks dark manganese oxide dendrites.",
                    separatingTest: "Specific gravity: Rhodonite is significantly denser (SG 3.65) than feldspar (SG 2.56).",
                    hardnessComparison: "Both Mohs 6.0"
                ),
                Lookalike(
                    mineralName: "Bustamite",
                    visualDifference: "Bustamite is calcium-manganese silicate with lighter brownish-pink color and lower hardness (5.5).",
                    separatingTest: "Optical analysis: Bustamite has different optic axial angle and lower SG (3.4).",
                    hardnessComparison: "Rhodonite 6.0 vs Bustamite 5.5"
                )
            ],
            ruleOutTests: [
                "Black Manganese Webbing: Distinctive network of black manganese oxide (pyrolusite) veins cutting through dusty rose-pink body.",
                "Knife Scratch Resistance: Steel pocket knife blade skates across the polished surface without scratching."
            ],
            careWarnings: [
                "Durable and tough for cabochons and jewelry carving.",
                "Safe for warm soapy water; avoid prolonged soaking in strong bleach."
            ],
            summary: "A robust manganese inosilicate known for its rose-pink color interlaced with striking dendritic veins and clouds of black manganese oxide.",
            geologicalOrigin: "Metamorphic alteration of manganese sediments and hydrothermal metasomatic skarns.",
            rarityAndOccurrence: "Australia (Broken Hill gem crystals), Russia (Urals), USA (Franklin, NJ; Massachusetts), Sweden."
        ))

        catalog.append(Mineral(
            name: "Kyanite",
            alternativeNames: ["Cyanite", "Disthene (meaning 'two strengths')"],
            category: .collectorStaples,
            family: "Nesosilicates",
            chemicalFormula: "Al₂SiO₅ (Polymorph with Andalusite and Sillimanite)",
            crystalSystem: "Triclinic (elongated bladed flat crystals in parallel aggregates)",
            mohsHardness: "Anisotropic: 4.5 - 5.0 parallel to blade length, 6.5 - 7.0 across blade width",
            minHardness: 4.5,
            maxHardness: 7.0,
            specificGravity: "3.53 - 3.67",
            luster: "Vitreous to pearly",
            streak: "White",
            cleavage: "Perfect in 1 direction {100}, distinct in another {010}",
            fracture: "Splintery",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.710 - 1.734",
            colorRange: ["Cornflower Blue", "Cyan Blue with Dark Center Streaks", "Teal Green", "Orange", "Black"],
            commonForms: [.rough, .cabochon, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Blue Sapphire (Corundum)",
                    visualDifference: "Sapphire forms hexagonal barrels, is much harder (Mohs 9), and has uniform hardness in all directions.",
                    separatingTest: "Dual-Hardness Test: Scratch parallel to length with pocket knife (scratches at Mohs 4.5); try scratching perpendicular (resists at Mohs 7.0).",
                    hardnessComparison: "Kyanite 4.5/7.0 vs Sapphire 9.0"
                ),
                Lookalike(
                    mineralName: "Blue Tourmaline (Indicolite)",
                    visualDifference: "Tourmaline has triangular prisms with vertical striations, not flat bladed sheets.",
                    separatingTest: "Crystal habit: Kyanite forms flat bladed sword-like slats; Tourmaline forms 3-sided prisms.",
                    hardnessComparison: "Kyanite 4.5/7.0 vs Tourmaline 7.5"
                ),
                Lookalike(
                    mineralName: "Dumortierite",
                    visualDifference: "Dumortierite is fibrous massive within quartz rather than separate bladed crystals.",
                    separatingTest: "Cleavage and habit: Kyanite has perfect 1-directional cleavage blades.",
                    hardnessComparison: "Kyanite 4.5/7.0 vs Dumortierite 7.0"
                )
            ],
            ruleOutTests: [
                "Diagnostic Dual Hardness (Anisotropy): Scratch with steel needle parallel to length (leaves scratch, Mohs 4.5); scratch across width (blade resists needle, Mohs 7.0).",
                "Sword-Blade Habit: Long, flat, bladed blue crystals embedded in quartz or mica schist matrix."
            ],
            careWarnings: [
                "Brittle along cleavage blades: prone to splitting if subjected to impact or pressure.",
                "Clean gently with soft dry brush."
            ],
            summary: "Famous for its extreme directional hardness (Mohs 4.5 lengthwise vs 7.0 across width), hence its historical name 'Disthene' ('two strengths'). A high-pressure metamorphic blue blade.",
            geologicalOrigin: "High-pressure regional metamorphism of clay-rich pelitic sedimentary rocks.",
            rarityAndOccurrence: "Nepal (superb gem blue), Brazil (Minas Gerais), Switzerland, USA (North Carolina, Georgia)."
        ))

        catalog.append(Mineral(
            name: "Epidote",
            alternativeNames: ["Pistacite", "Unakite component"],
            category: .collectorStaples,
            family: "Sorosilicates",
            chemicalFormula: "Ca₂(Al,Fe)₃(SiO₄)(Si₂O₇)O(OH)",
            crystalSystem: "Monoclinic (prismatic elongated crystals with striations, massive granular)",
            mohsHardness: "6.0 - 7.0",
            minHardness: 6.0,
            maxHardness: 7.0,
            specificGravity: "3.35 - 3.50",
            luster: "Vitreous to resinous",
            streak: "Greyish-white to greenish-white",
            cleavage: "Perfect in 1 direction {001}, imperfect in {100}",
            fracture: "Uneven to conchoidal (brittle)",
            transparency: "Transparent to Opaque",
            refractiveIndex: "1.715 - 1.797",
            colorRange: ["Pistachio Green", "Olive Green", "Yellow-Green", "Brownish Green", "Blackish Green"],
            commonForms: [.rough, .cabochon, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Olivine (Peridot)",
                    visualDifference: "Peridot is bright lime/olive green with conchoidal fracture and lacks perfect 1-way cleavage.",
                    separatingTest: "Cleavage check: Epidote shows sharp flat mirror cleavage planes; Olivine has conchoidal glassy fracture.",
                    hardnessComparison: "Both Mohs 6.5"
                ),
                Lookalike(
                    mineralName: "Green Tourmaline",
                    visualDifference: "Tourmaline has 3-sided triangular cross-sections without perfect basal cleavage.",
                    separatingTest: "Crystal habit: Epidote crystals are monoclinic prisms often terminating in wedge shapes.",
                    hardnessComparison: "Epidote 6.5 vs Tourmaline 7.5"
                ),
                Lookalike(
                    mineralName: "Vesuvianite (Idocrase)",
                    visualDifference: "Vesuvianite crystallizes in tetragonal prisms with square cross-sections.",
                    separatingTest: "Crystal symmetry: Vesuvianite has 4-fold tetragonal symmetry; Epidote is monoclinic.",
                    hardnessComparison: "Both Mohs 6.5"
                )
            ],
            ruleOutTests: [
                "Pistachio Green Color: Unique 'pistachio' yellowish-green hue caused by Fe³⁺ in sorosilicate lattice.",
                "Strong Pleochroism: Rotates from green to brown to yellow under polarized light."
            ],
            careWarnings: [
                "Durable and resistant to weathering.",
                "Safe for water and standard cleaning methods."
            ],
            summary: "A calcium iron sorosilicate renowned for its diagnostic pistachio-green color, wedge-shaped monoclinic crystals, and presence alongside pink feldspar in Unakite.",
            geologicalOrigin: "Regional and contact metamorphism of calcium-rich igneous rocks and calc-silicate skarns.",
            rarityAndOccurrence: "Austria (Knappenwand), France (Bourg d'Oisans), Pakistan, USA (Alaska Prince of Wales Island)."
        ))

        catalog.append(Mineral(
            name: "Vanadinite",
            alternativeNames: ["Lead Chlorovanadate"],
            category: .collectorStaples,
            family: "Phosphates / Vanadates (Apatite Group)",
            chemicalFormula: "Pb₅(VO₄)₃Cl",
            crystalSystem: "Hexagonal (sharp 6-sided hexagonal prisms and barrels)",
            mohsHardness: "2.75 - 3.0",
            minHardness: 2.75,
            maxHardness: 3.0,
            specificGravity: "6.80 - 7.10 (Extremely Dense)",
            luster: "Adamantine to resinous (sparkles like jewels)",
            streak: "White to pale yellow",
            cleavage: "None",
            fracture: "Uneven to conchoidal; brittle",
            transparency: "Transparent to Translucent",
            refractiveIndex: "2.350 - 2.416 (Extreme diamond-like refraction)",
            colorRange: ["Bright Ruby Red", "Orange-Red", "Amber Orange", "Brownish Yellow"],
            commonForms: [.rough, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Wulfenite",
                    visualDifference: "Wulfenite forms thin square or tabular tetragonal plates, not 6-sided hexagonal prisms.",
                    separatingTest: "Crystal symmetry: Vanadinite forms 6-sided hexagonal prisms; Wulfenite forms 4-sided square plates.",
                    hardnessComparison: "Both Mohs ~3.0",
                    diagnosticReaction: "Heft: Both are dense lead minerals (SG ~7.0)."
                ),
                Lookalike(
                    mineralName: "Pyromorphite",
                    visualDifference: "Pyromorphite is apple green to yellow-green, while Vanadinite is fiery ruby red/orange.",
                    separatingTest: "Color & Chemical test: Vanadinite is vanadium-rich red; Pyromorphite is phosphorus-rich green.",
                    hardnessComparison: "Both Mohs 3.0"
                ),
                Lookalike(
                    mineralName: "Crocoite",
                    visualDifference: "Crocoite forms long slender monoclinic needle-like saffron-orange prisms.",
                    separatingTest: "Streak test: Crocoite streak is bright orange-yellow; Vanadinite streak is pale yellow-white.",
                    hardnessComparison: "Vanadinite 3.0 vs Crocoite 2.5 - 3.0"
                )
            ],
            ruleOutTests: [
                "Hexagonal Prism Geometry: Clusters of miniature 6-sided hexagonal pillars with flat roof terminations.",
                "Extreme Density Heft: Feels astonishingly heavy in the palm (SG ~7.0, nearly the density of iron).",
                "Adamantine Luster: High refractive index (2.4) gives crystals a fiery jewel-like sparkle."
            ],
            careWarnings: [
                "TOXICITY: Contains lead (Pb) and vanadium (V). Handle carefully, wash hands, and keep away from children.",
                "Soft (Mohs 3) and brittle: never tumble or subject to mechanical cleaning."
            ],
            summary: "A breathtaking collector mineral forming fiery ruby-red and orange hexagonal prisms with extraordinary lead-heavy heft (SG 6.9) and diamond-like adamantine sparkle.",
            geologicalOrigin: "Supergene oxidation zones of lead deposits in arid climates where vanadium is leached from surrounding wall rocks.",
            rarityAndOccurrence: "Morocco (Mibladen - world's finest specimens), USA (Arizona Apache Mine), Namibia."
        ))

        // ==========================================
        // 4. SHOP REGULARS (12)
        // ==========================================
        catalog.append(Mineral(
            name: "Tiger's Eye",
            alternativeNames: ["Pseudomorphic Quartz", "Hawk's Eye (Blue)", "Tiger Iron"],
            category: .shopRegulars,
            family: "Quartz (Pseudomorph after Crocidolite Asbestos)",
            chemicalFormula: "SiO₂ with oriented limonite / goethite fibers",
            crystalSystem: "Trigonal (fibrous aggregate)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.64 - 2.71",
            luster: "Silky (chatoyant)",
            streak: "White to yellowish-brown",
            cleavage: "None",
            fracture: "Fibrous to splintery",
            transparency: "Opaque",
            refractiveIndex: "1.540 - 1.553",
            colorRange: ["Golden Yellow", "Honey Brown", "Midnight Blue (Hawk's Eye)", "Reddish-Brown (Heat Treated / Bull's Eye)"],
            commonForms: [.cabochon, .tumbled, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Pietersite",
                    visualDifference: "Pietersite is a brecciated (shattered and re-cemented) chaotic swirl of hawk's eye and tiger's eye fibers.",
                    separatingTest: "Pattern structure: Tiger's eye fibers are parallel and linear; Pietersite shows swirling storm-like fractured segments.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Cat's Eye Chrysoberyl",
                    visualDifference: "Chrysoberyl is transparent/translucent with a razor-sharp single slit line and is much harder (Mohs 8.5).",
                    separatingTest: "Hardness & Transparency: Chrysoberyl is Mohs 8.5 (scratches quartz easily); Tiger's eye is opaque Mohs 7.0.",
                    hardnessComparison: "Tiger's Eye 7.0 vs Chrysoberyl 8.5"
                ),
                Lookalike(
                    mineralName: "Fiber Optic Glass (Cat's Eye Glass)",
                    visualDifference: "Man-made fiber optic glass shows unnaturally uniform parallel straight fibers in synthetic electric colors.",
                    separatingTest: "Magnification test: Glass shows uniform honeycomb fiber matrix under loupe.",
                    hardnessComparison: "Tiger's Eye 7.0 vs Glass 5.5"
                )
            ],
            ruleOutTests: [
                "Silky Chatoyancy Effect: Tilt the stone back and forth under light; the golden bands shift and shimmer like silk.",
                "Knife scratch: Pocket knife cannot scratch the surface (Mohs 7.0)."
            ],
            careWarnings: [
                "Extremely safe in finished polished form (silica completely replaced crocidolite asbestos fibers).",
                "Durable and safe for water and all everyday jewelry wear."
            ],
            summary: "A golden-brown chatoyant quartz pseudomorph where parallel fibers of crocidolite asbestos were altered into iron oxides and cemented by microcrystalline silica.",
            geologicalOrigin: "Metamorphic banded iron formations.",
            rarityAndOccurrence: "Abundant; South Africa (Northern Cape - world's primary source), Western Australia."
        ))

        catalog.append(Mineral(
            name: "Obsidian",
            alternativeNames: ["Volcanic Glass", "Snowflake Obsidian", "Rainbow Obsidian", "Mahogany Obsidian", "Apache Tears"],
            category: .shopRegulars,
            family: "Igneous Rock / Volcanic Glass",
            chemicalFormula: "70-75% SiO₂ + MgO, Fe₃O₄ volcanic amorphous melt",
            crystalSystem: "Amorphous (non-crystalline volcanic glass)",
            mohsHardness: "5.0 - 5.5",
            minHardness: 5.0,
            maxHardness: 5.5,
            specificGravity: "2.35 - 2.60",
            luster: "Vitreous (glassy)",
            streak: "White",
            cleavage: "None",
            fracture: "Perfect Conchoidal (produces molecularly sharp razor edges)",
            transparency: "Translucent on thin edges to Opaque",
            refractiveIndex: "1.480 - 1.510",
            colorRange: ["Jet Black", "Black with White Cristobalite Snowflakes", "Mahogany Red-Brown", "Gold/Silver Sheen", "Rainbow Iridescence"],
            commonForms: [.rough, .cabochon, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Black Tourmaline (Schorl)",
                    visualDifference: "Tourmaline has crystalline triangular striations and is much harder (Mohs 7.5).",
                    separatingTest: "Hardness test: Tourmaline scratches window glass and quartz; Obsidian is scratched by a quartz crystal.",
                    hardnessComparison: "Obsidian 5.5 vs Tourmaline 7.5"
                ),
                Lookalike(
                    mineralName: "Black Onyx (Dyed Chalcedony)",
                    visualDifference: "Onyx is microcrystalline quartz (Mohs 7.0) with waxy luster and lacks razor-sharp glass fracture.",
                    separatingTest: "Hardness: Quartz point scratches obsidian easily; cannot scratch black onyx.",
                    hardnessComparison: "Obsidian 5.5 vs Black Onyx 7.0"
                ),
                Lookalike(
                    mineralName: "Industrial Slag Glass",
                    visualDifference: "Slag glass often contains round gas bubbles, swirl streaks, and non-volcanic colors.",
                    separatingTest: "Geological context & internal inclusions: Obsidian contains flow bands of microscopic mineral crystallites.",
                    hardnessComparison: "Both Mohs 5.5"
                )
            ],
            ruleOutTests: [
                "Conchoidal Razor Fracture: Curved, shell-like fracture scars that taper to razor-sharp glass cutting edges.",
                "Quartz Scratch: A quartz crystal tip easily scores a scratch across the obsidian surface."
            ],
            careWarnings: [
                "Sharp fracture hazard: rough broken edges can cut skin like surgical scalpel blades.",
                "Protect from drops and hard knocks which cause edge chipping."
            ],
            summary: "Extrusive volcanic glass formed when high-silica felsic lava cools so rapidly that crystal lattice structures have no time to form. Renowned for ancient blade crafting.",
            geologicalOrigin: "Rapidly quenched rhyolitic lava flows.",
            rarityAndOccurrence: "Common in volcanic arcs; Mexico, USA (Oregon Glass Buttes, California), Iceland, Japan."
        ))

        catalog.append(Mineral(
            name: "Sodalite",
            alternativeNames: ["Poor Man's Lapis", "Princess Blue"],
            category: .shopRegulars,
            family: "Tectosilicates (Feldspathoid Group)",
            chemicalFormula: "Na₈(Al₆Si₆O₂₄)Cl₂",
            crystalSystem: "Isometric (massive compact aggregates, rarely dodecahedrons)",
            mohsHardness: "5.5 - 6.0",
            minHardness: 5.5,
            maxHardness: 6.0,
            specificGravity: "2.14 - 2.40 (Light)",
            luster: "Vitreous to greasy",
            streak: "White",
            cleavage: "Poor / indistinct in 6 directions {110}",
            fracture: "Conchoidal to uneven",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.483 - 1.487",
            colorRange: ["Royal Blue", "Deep Navy Blue", "Denim Blue with White Nepheline/Calcite Veins", "Yooperlite (fluorescent variety)"],
            commonForms: [.cabochon, .tumbled, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Lapis Lazuli",
                    visualDifference: "Lapis contains golden brassy pyrite flecks and is richer ultramarine; Sodalite has white veins and lacks pyrite.",
                    separatingTest: "Pyrite & Streak: Sodalite leaves a white streak and lacks gold pyrite; Lapis leaves a light blue streak with pyrite specks.",
                    hardnessComparison: "Sodalite 5.5 - 6.0 vs Lapis 5.0 - 5.5"
                ),
                Lookalike(
                    mineralName: "Azurite",
                    visualDifference: "Azurite is copper carbonate (Mohs 3.5) that fizzes in acid and has intense electric cobalt color.",
                    separatingTest: "Hardness & Acid: Azurite is scratched by copper penny and fizzes in vinegar; Sodalite is inert and harder.",
                    hardnessComparison: "Sodalite 5.5 - 6.0 vs Azurite 3.5"
                ),
                Lookalike(
                    mineralName: "Dumortierite",
                    visualDifference: "Dumortierite is darker denim/slate blue with higher hardness (Mohs 7.0).",
                    separatingTest: "Hardness: Dumortierite scratches glass easily; Sodalite is scored by quartz.",
                    hardnessComparison: "Sodalite 5.5 - 6.0 vs Dumortierite 7.0"
                )
            ],
            ruleOutTests: [
                "White Veining & Lack of Pyrite: Royal blue background laced with white calcite/nepheline veins and zero golden pyrite.",
                "UV Fluorescence ('Yooperlite'): Sodalite syenite from Lake Superior glows blazing fiery orange under 365nm UV."
            ],
            careWarnings: [
                "Sensitive to prolonged acid contact.",
                "Safe for water immersion and standard jewelry wear."
            ],
            summary: "A sodium-rich feldspathoid mineral famous for its rich royal-navy blue color laced with white calcite webbing. The fluorescent variety 'Yooperlite' glows bright orange under UV.",
            geologicalOrigin: "Silica-undersaturated nepheline syenite igneous plutons and metasomatic pegmatites.",
            rarityAndOccurrence: "Canada (Princess Sodalite Mine, Ontario), Brazil (Bahia), USA (Michigan Yooperlites), Namibia."
        ))

        catalog.append(Mineral(
            name: "Unakite",
            alternativeNames: ["Unakite Jasper (misnomer)", "Epidote-Granite"],
            category: .shopRegulars,
            family: "Metamorphic Rock (Epidote + Orthoclase Feldspar + Quartz)",
            chemicalFormula: "Rock mixture: Epidote + KAlSi₃O₈ + SiO₂",
            crystalSystem: "Aggregate rock mixture",
            mohsHardness: "6.0 - 7.0",
            minHardness: 6.0,
            maxHardness: 7.0,
            specificGravity: "2.85 - 3.20",
            luster: "Vitreous to dull",
            streak: "White to pale greenish",
            cleavage: "None (massive rock)",
            fracture: "Uneven to splintery",
            transparency: "Opaque",
            refractiveIndex: "1.520 - 1.760 (composite)",
            colorRange: ["Mottled Olive/Pistachio Green and Salmon Pink with Clear Quartz spots"],
            commonForms: [.tumbled, .cabochon, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Dragon Blood Jasper",
                    visualDifference: "Dragon blood jasper is dark forest green epidote with crimson red piedmontite/jasper patches, not salmon pink feldspar.",
                    separatingTest: "Color inspection: Unakite is distinctly pastel salmon-pink (feldspar) and pistachio green (epidote).",
                    hardnessComparison: "Both Mohs 6.0 - 7.0"
                ),
                Lookalike(
                    mineralName: "Rhodonite in Matrix",
                    visualDifference: "Rhodonite has black manganese veins rather than pistachio green epidote.",
                    separatingTest: "Color palette: Rhodonite is rose pink and black; Unakite is salmon pink and olive green.",
                    hardnessComparison: "Both Mohs 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Ocean Jasper",
                    visualDifference: "Ocean jasper features orbicular circular bulls-eye rings rather than granite granular texture.",
                    separatingTest: "Pattern: Ocean jasper has circular eyes; Unakite has crystalline interlocking granite grains.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Iconic Salmon-Pink and Olive-Green Palette: Granular interlocking mix of pistachio green epidote, peach-pink orthoclase feldspar, and gray quartz.",
                "Knife Scratch Resistance: Resists scratching by standard steel pocket knife."
            ],
            careWarnings: [
                "Very durable and tough rock for tumbling and everyday jewelry.",
                "Safe for water and standard cleansers."
            ],
            summary: "An altered granitic rock consisting of pistachio-green epidote, salmon-pink orthoclase feldspar, and clear quartz. Named after the Unaka Mountains of North Carolina.",
            geologicalOrigin: "Hydrothermal epidotization of granitic rocks.",
            rarityAndOccurrence: "Abundant; USA (Unaka Mountains, NC/TN; Lake Superior pebbles), South Africa, China."
        ))

        catalog.append(Mineral(
            name: "Howlite",
            alternativeNames: ["White Turquoise (misnomer)", "Silicoborocalcite", "Kaolinite lookalike"],
            category: .shopRegulars,
            family: "Borates",
            chemicalFormula: "Ca₂B₅SiO₉(OH)₅",
            crystalSystem: "Monoclinic (nodular cauliflower-like masses)",
            mohsHardness: "3.5",
            minHardness: 3.5,
            maxHardness: 3.5,
            specificGravity: "2.45 - 2.58",
            luster: "Subvitreous, porcelain-like to dull",
            streak: "White",
            cleavage: "None in massive form",
            fracture: "Even to subconchoidal (porcelain feel)",
            transparency: "Opaque (translucent in microscopic crystals)",
            refractiveIndex: "1.586 - 1.605",
            colorRange: ["Porcelain White", "Ivory Cream with Dark Grey or Black Webbed Spiderweb Veins"],
            commonForms: [.tumbled, .cabochon, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Magnesite",
                    visualDifference: "Magnesite is slightly harder (Mohs 4.0 - 4.5) and chalkier.",
                    separatingTest: "Hardness and acid test: Magnesite is MgCO₃; Howlite is calcium borosilicate (non-carbonate).",
                    hardnessComparison: "Howlite 3.5 vs Magnesite 4.0 - 4.5"
                ),
                Lookalike(
                    mineralName: "White Turquoise (Genuine)",
                    visualDifference: "Genuine white turquoise is extremely rare, harder (Mohs 5.5 - 6.0), and contains copper/aluminum phosphate.",
                    separatingTest: "Hardness test: Copper penny scratches Howlite (Mohs 3.5); Genuine turquoise cannot be scratched by copper penny.",
                    hardnessComparison: "Howlite 3.5 vs Turquoise 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Dyed Blue Turquenite",
                    visualDifference: "Howlite is dyed bright cyan-blue to imitate turquoise in commercial jewelry.",
                    separatingTest: "Acetone test: Swabbing dyed howlite with acetone turns cotton blue; scraping reveals bright white interior.",
                    hardnessComparison: "Mohs 3.5"
                )
            ],
            ruleOutTests: [
                "Cauliflower White Matrix: Milk-white porcelain body interlaced with organic dark grey/black spiderweb veins.",
                "Copper Penny Scratch: Can be scratched by firm pressure with a copper penny (Mohs 3.5)."
            ],
            careWarnings: [
                "Soft (Mohs 3.5) and porous: easily scratched and absorbs body oils, cosmetics, and dyes.",
                "Clean only with a soft dry or barely damp microfiber cloth."
            ],
            summary: "A calcium borosilicate celebrated in natural form for its pure porcelain-white color laced with dark web-like veins. Extensively dyed blue as an imitation for turquoise.",
            geologicalOrigin: "Evaporite deposits in arid saline lake basins.",
            rarityAndOccurrence: "Abundant; Canada (Nova Scotia - type locality), USA (California Death Valley & Tick Canyon)."
        ))

        catalog.append(Mineral(
            name: "Carnelian",
            alternativeNames: ["Cornelian", "Red Chalcedony"],
            category: .shopRegulars,
            family: "Quartz (Microcrystalline / Chalcedony)",
            chemicalFormula: "SiO₂ with dispersed iron oxide (Fe₂O₃) nanoparticles",
            crystalSystem: "Trigonal (microcrystalline aggregate)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.59 - 2.61",
            luster: "Waxy to vitreous",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Translucent to Semi-transparent",
            refractiveIndex: "1.530 - 1.539",
            colorRange: ["Fiery Orange", "Red-Orange", "Amber Honey", "Deep Carnelian Red", "Brownish-Red (Sard)"],
            commonForms: [.tumbled, .cabochon, .carved, .rough, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Red Jasper",
                    visualDifference: "Jasper is 100% opaque; Carnelian is warmly translucent when backlit.",
                    separatingTest: "Flashlight Backlight Test: Hold phone flashlight against the stone; carnelian glows fiery orange throughout; Jasper blocks 100% of light.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Amber",
                    visualDifference: "Amber is fossil resin that floats in salt water, feels warm, and is soft (Mohs 2.0 - 2.5).",
                    separatingTest: "Hardness & Density: Carnelian is hard stone (Mohs 7.0, SG 2.6); Amber is soft organic resin (Mohs 2.5, SG 1.08).",
                    hardnessComparison: "Carnelian 7.0 vs Amber 2.0 - 2.5"
                ),
                Lookalike(
                    mineralName: "Fire Agate",
                    visualDifference: "Fire agate has botryoidal iridescence and rainbow metallic flash.",
                    separatingTest: "Optical flash: Carnelian has uniform warm glow; Fire agate displays schiller interference colors.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Backlit Translucent Glow: Shines a warm luminous amber/orange glow when held over a flashlight.",
                "Hardness: Scratches steel knife blades without scratching itself."
            ],
            careWarnings: [
                "Very tough and durable for rings, signets, and pendants.",
                "Safe for water, sunlight, and everyday wear."
            ],
            summary: "A translucent orange-to-red variety of chalcedony colored by colloidal iron oxides. Revered since ancient Roman and Egyptian times for signet rings and protective amulets.",
            geologicalOrigin: "Low-temperature silica precipitates in cavities of volcanic basalt lavas.",
            rarityAndOccurrence: "Common; India (Gujarat - famous sun-baked carnelian), Madagascar, Brazil, Uruguay."
        ))

        catalog.append(Mineral(
            name: "Bloodstone",
            alternativeNames: ["Heliotrope", "Blood Jasper"],
            category: .shopRegulars,
            family: "Quartz (Chalcedony / Jasper)",
            chemicalFormula: "SiO₂ with chlorite/amphibole (green) and hematite (red spots)",
            crystalSystem: "Trigonal (microcrystalline aggregate)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.58 - 2.64",
            luster: "Vitreous to waxy / greasy",
            streak: "White (red spots can leave pale reddish streak)",
            cleavage: "None",
            fracture: "Conchoidal to splintery",
            transparency: "Opaque to Translucent on thin edges",
            refractiveIndex: "1.530 - 1.540",
            colorRange: ["Dark Forest Green with Crimson / Blood-Red Flecks and Spots"],
            commonForms: [.cabochon, .tumbled, .carved, .rough],
            topLookalikes: [
                Lookalike(
                    mineralName: "Dragon Blood Jasper",
                    visualDifference: "Dragon blood jasper is epidote-based with larger red piedmontite patches, not dark green chalcedony with pinpoint blood droplets.",
                    separatingTest: "Color & texture: Bloodstone has dense dark teal-green chalcedony base with pinpoint droplets of bright red hematite.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Moss Agate",
                    visualDifference: "Moss agate is clear/white chalcedony with green dendritic mineral filaments, lacking red hematite spots.",
                    separatingTest: "Visual inspection: Bloodstone has solid opaque dark green body; Moss agate has transparent base.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Fancy Jasper",
                    visualDifference: "Fancy jasper contains swirls of mustard, mauve, and green without discrete blood-red specks.",
                    separatingTest: "Pattern: Bloodstone specifically features discrete blood droplet flecks.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Blood-Red Fleck Inspection: Deep forest-green chalcedony base peppered with discrete crimson-red dots of hematite.",
                "Knife Scratch Resistance: Resists scratching from hardened steel knife blade."
            ],
            careWarnings: [
                "Extremely durable and tough for everyday rings and pendants.",
                "Safe for water immersion and ultrasonic cleaning."
            ],
            summary: "A dark green microcrystalline quartz (chalcedony) punctuated by vivid droplets of crimson-red hematite resembling drops of blood. The traditional March birthstone.",
            geologicalOrigin: "Low-temperature silica precipitates in volcanic cavities and weathered zones.",
            rarityAndOccurrence: "India (Deccan Traps - primary global source), Madagascar, Brazil, Australia, Scotland (Isle of Rum)."
        ))

        catalog.append(Mineral(
            name: "Moonstone",
            alternativeNames: ["Orthoclase Moonstone", "Adularia", "Rainbow Moonstone (Labradorite)"],
            category: .shopRegulars,
            family: "Tectosilicates (Feldspar Group - Orthoclase/Albite Intergrowth)",
            chemicalFormula: "KAlSi₃O₈ with alternating exsolution lamellae of NaAlSi₃O₈",
            crystalSystem: "Monoclinic (Orthoclase) / Triclinic (Albite)",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.56 - 2.59",
            luster: "Vitreous to pearly",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at 90°",
            fracture: "Uneven to conchoidal (brittle)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.518 - 1.526",
            colorRange: ["Milky White", "Silvery Blue Sheen (Adularescence)", "Peach", "Grey", "Rainbow (Labradorite)"],
            commonForms: [.cabochon, .tumbled, .cut, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Opalite (Man-made Glass)",
                    visualDifference: "Opalite is synthetic glass that glows milky orange when backlit and lacks true floating adularescent optical wave.",
                    separatingTest: "Transmitted Light Test: Opalite turns bright fiery orange when held over flashlight; Natural moonstone remains cool white/blue.",
                    hardnessComparison: "Moonstone 6.0 - 6.5 vs Opalite Glass 5.5"
                ),
                Lookalike(
                    mineralName: "Rainbow Moonstone (White Labradorite)",
                    visualDifference: "Rainbow moonstone is actually plagioclase feldspar displaying multi-color spectral flashes (blue, yellow, green) rather than single blue/white adularescence.",
                    separatingTest: "Refractive index: Orthoclase moonstone RI is 1.52; Rainbow labradorite RI is 1.56.",
                    hardnessComparison: "Both Mohs 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Chalcedony",
                    visualDifference: "Chalcedony lacks the undulating billowy moonlit sheen (adularescence) across cleavage planes.",
                    separatingTest: "Optical effect: Tilt stone in light; moonstone shows floating blue-white sheet of light.",
                    hardnessComparison: "Moonstone 6.0 - 6.5 vs Chalcedony 7.0"
                )
            ],
            ruleOutTests: [
                "Adularescence Sheen: Tilt cabochon in hand; a billowy, silvery-blue light glides across the dome like moonlight on water.",
                "Two 90° Cleavage Directions: Internal cleavage planes reflect light at right angles."
            ],
            careWarnings: [
                "Feldspar cleavage makes moonstone vulnerable to pressure and sharp blows; set in protective bezel rings.",
                "Clean with warm soapy water; avoid steam and ultrasonic cleaners."
            ],
            summary: "A potassium feldspar gemstone celebrated for its enchanting 'adularescence'—a floating ethereal blue-white shimmer caused by light scattering between microscopic albite layers.",
            geologicalOrigin: "Slowly cooled granitic pegmatites and hydrothermal alpine veins (adularia).",
            rarityAndOccurrence: "Sri Lanka (premier royal blue sheen), India (rainbow/peach), Myanmar, Madagascar."
        ))

        catalog.append(Mineral(
            name: "Sunstone",
            alternativeNames: ["Aventurescent Feldspar", "Heliolite", "Oregon Sunstone"],
            category: .shopRegulars,
            family: "Tectosilicates (Feldspar Group - Oligoclase / Plagioclase)",
            chemicalFormula: "(Na,Ca)Al₁₋₂Si₃₋₂O₈ with oriented copper / hematite / goethite platelets",
            crystalSystem: "Triclinic",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.62 - 2.65",
            luster: "Vitreous to sparkling aventurescent",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at ~86°",
            fracture: "Uneven to conchoidal",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.537 - 1.547",
            colorRange: ["Golden Peach", "Warm Amber", "Champagne with Metallic Red / Copper Glitter Shimmer", "Dichroic Green/Red (Oregon)"],
            commonForms: [.cut, .cabochon, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Goldstone (Man-made Glitter Glass)",
                    visualDifference: "Goldstone is synthetic reddish-brown glass densely packed with unnaturally uniform triangular copper crystal flakes.",
                    separatingTest: "Magnification & Matrix: Goldstone shows dense artificial copper triangles in glass base; Natural sunstone has natural feldspar cleavages and organic Schiller.",
                    hardnessComparison: "Sunstone 6.0 - 6.5 vs Goldstone 5.5"
                ),
                Lookalike(
                    mineralName: "Aventurine (Green/Orange Quartz)",
                    visualDifference: "Aventurine is quartz (Mohs 7.0) with mica flake glitter, lacking feldspar 2-direction cleavage.",
                    separatingTest: "Hardness test: Quartz aventurine is Mohs 7.0; Sunstone feldspar is Mohs 6.0 - 6.5.",
                    hardnessComparison: "Sunstone 6.0 - 6.5 vs Aventurine 7.0"
                ),
                Lookalike(
                    mineralName: "Carnelian",
                    visualDifference: "Carnelian has a smooth waxy glow without sparkling metallic reflective glitter flakes (aventurescence).",
                    separatingTest: "Optical effect: Sunstone flashes metallic copper confetti flakes; Carnelian is uniform translucent chalcedony.",
                    hardnessComparison: "Sunstone 6.5 vs Carnelian 7.0"
                )
            ],
            ruleOutTests: [
                "Aventurescence Schiller Flash: Bright metallic confetti-like flashes of microscopic native copper or hematite platelets sparkling under direct light.",
                "Feldspar Cleavage: Two reflective cleavage planes intersecting near right angles."
            ],
            careWarnings: [
                "Cleavage planes can split if subjected to hard impacts; avoid rough ring wear.",
                "Safe for warm soapy water cleaning."
            ],
            summary: "A plagioclase feldspar imbued with internal platelets of native copper or hematite that catch the light in a dazzling metallic glitter display called aventurescence.",
            geologicalOrigin: "Basalt lava flows (Oregon Sunstone) and granitic pegmatites.",
            rarityAndOccurrence: "USA (Oregon Ponderosa Mine - state gem), India, Norway, Tanzania."
        ))

        catalog.append(Mineral(
            name: "Amazonite",
            alternativeNames: ["Amazonstone", "Green Microcline"],
            category: .shopRegulars,
            family: "Tectosilicates (Potassium Feldspar - Microcline)",
            chemicalFormula: "KAlSi₃O₈ with trace Pb²⁺ (lead) and H₂O color centers",
            crystalSystem: "Triclinic",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.56 - 2.58",
            luster: "Vitreous to pearly on cleavages",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at near 90° (89.5°)",
            fracture: "Uneven to conchoidal",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.522 - 1.530",
            colorRange: ["Vivid Turquoise Green", "Mint Green", "Teal Blue with White Grid-Like Albite Perlescence"],
            commonForms: [.rough, .cabochon, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Turquoise",
                    visualDifference: "Turquoise is phosphate without grid-pattern feldspar cleavages and has waxy luster.",
                    separatingTest: "Feldspar grid & Cleavage: Amazonite shows white perthitic grid stripes and flashes flat 90° cleavage planes; Turquoise is non-cleavable.",
                    hardnessComparison: "Both Mohs 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Chrysoprase (Green Chalcedony)",
                    visualDifference: "Chrysoprase is nickel-rich apple-green chalcedony with smooth waxy texture and no cleavage.",
                    separatingTest: "Cleavage check: Amazonite has flat 90° cleavage steps; Chrysoprase has conchoidal fracture.",
                    hardnessComparison: "Amazonite 6.0 vs Chrysoprase 7.0"
                ),
                Lookalike(
                    mineralName: "Larimar",
                    visualDifference: "Larimar is sky-blue with needle spray radiating patterns, not mint/teal green with grid cleavage.",
                    separatingTest: "Color and habit: Amazonite has distinct green-teal microcline feldspar structure.",
                    hardnessComparison: "Amazonite 6.0 - 6.5 vs Larimar 4.5 - 5.0"
                )
            ],
            ruleOutTests: [
                "Perthitic White Grid Webbing: Look closely at crystal surface: fine white interlaced albite exsolution lamellae form a grid or marble pattern.",
                "Two 90° Cleavage Planes: Flash stone in light to observe two flat reflective planes."
            ],
            careWarnings: [
                "Protect from strong impacts that could trigger cleavage along crystal planes.",
                "Safe for water and mild soap cleansers."
            ],
            summary: "A striking mint-green to blue-teal variety of microcline feldspar colored by trace lead impurities and structural water, patterned with delicate white perthitic streaks.",
            geologicalOrigin: "Granitic pegmatite pockets associated with smoky quartz and cleavelandite.",
            rarityAndOccurrence: "USA (Pikes Peak, Colorado), Russia (Ilmen Mountains), Madagascar, Brazil, Ethiopia."
        ))

        catalog.append(Mineral(
            name: "Chrysocolla",
            alternativeNames: ["Copper Silicate Gel", "Eilat Stone (composite)"],
            category: .shopRegulars,
            family: "Phyllosilicates (Hydrated Copper Silicate)",
            chemicalFormula: "Cu₂₋ₓAlₓ(H₂₋ₓSi₂O₅)(OH)₄·nH₂O",
            crystalSystem: "Orthorhombic / Amorphous gel aggregate (massive botryoidal crusts and veins)",
            mohsHardness: "2.0 - 4.0 (up to 6.5 - 7.0 when naturally silicified with quartz 'gem silica')",
            minHardness: 2.0,
            maxHardness: 4.0,
            specificGravity: "1.93 - 2.40 (Very Light)",
            luster: "Vitreous, waxy, to earthy dull",
            streak: "Light Greenish-Blue",
            cleavage: "None",
            fracture: "Conchoidal to earthy",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.575 - 1.599",
            colorRange: ["Vivid Cyan Blue", "Turquoise Green", "Sky Blue", "Dark Navy Swirls with Malachite"],
            commonForms: [.cabochon, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Turquoise",
                    visualDifference: "Turquoise is denser (SG 2.8), harder (Mohs 5.5 - 6), and does not stick to a damp tongue.",
                    separatingTest: "Tongue Adhesion & Hardness: Porous chrysocolla sticks noticeably to a moist tongue/finger due to extreme porosity; Turquoise does not adhere.",
                    hardnessComparison: "Chrysocolla 2.0 - 4.0 vs Turquoise 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Malachite",
                    visualDifference: "Malachite is rich emerald green with dark concentric rings; Chrysocolla is vivid cyan blue.",
                    separatingTest: "Color & Density: Malachite is green and heavy (SG 4.0); Chrysocolla is cyan-blue and light (SG 2.2).",
                    hardnessComparison: "Chrysocolla 2.5 vs Malachite 4.0"
                ),
                Lookalike(
                    mineralName: "Azurite",
                    visualDifference: "Azurite is deep indigo royal blue (Mohs 3.5 - 4) and fizzes in acid.",
                    separatingTest: "Acid reaction: Azurite effervesces violently; Chrysocolla decomposes without bubbling.",
                    hardnessComparison: "Both Mohs 2.5 - 4.0"
                )
            ],
            ruleOutTests: [
                "Tongue Stick Porosity Test: Lightly touch a dry edge to a moistened lip; absorbent porosity causes noticeable sticking adhesion.",
                "Cyan Blue Color: Electric cyan/turquoise blue hues associated with copper ore zones."
            ],
            careWarnings: [
                "Soft and porous (Mohs 2 - 4 unless silicified): avoid exposure to acids, oils, soaps, and ultrasonic cleaners.",
                "Store carefully in padded jewelry slots."
            ],
            summary: "A captivating cyan-blue hydrated copper phyllosilicate. Often intergrown with malachite, azurite, and quartz (creating the valuable hard 'Gem Silica' variety).",
            geologicalOrigin: "Supergene oxidation zones of copper porphyry deposits.",
            rarityAndOccurrence: "Common in copper regions; USA (Arizona Inspiration Mine), DR Congo, Chile, Peru, Israel (King Solomon Mines / Eilat)."
        ))

        catalog.append(Mineral(
            name: "Lepidolite",
            alternativeNames: ["Lithium Mica", "Lavender Mica", "Flower Sugilite lookalike"],
            category: .shopRegulars,
            family: "Phyllosilicates (Mica Group)",
            chemicalFormula: "K(Li,Al)₃(Al,Si,Rb)₄O₁₀(F,OH)₂",
            crystalSystem: "Monoclinic (scaly granular aggregates, tabular pseudohexagonal books)",
            mohsHardness: "2.5 - 3.5",
            minHardness: 2.5,
            maxHardness: 3.5,
            specificGravity: "2.80 - 2.90",
            luster: "Pearly to vitreous (sparkling flaky sheen)",
            streak: "White",
            cleavage: "Perfect basal in 1 direction {001}, yielding flexible elastic flakes",
            fracture: "Uneven (scaly)",
            transparency: "Translucent to Transparent in thin sheets",
            refractiveIndex: "1.525 - 1.587",
            colorRange: ["Lilac Pink", "Lavender Purple", "Violet-Rose", "Silver Grey with Pink Flakes"],
            commonForms: [.rough, .cabochon, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Sugilite",
                    visualDifference: "Sugilite is much harder (Mohs 6.0 - 6.5), massive waxy purple cyclosilicate without glistening mica flakes.",
                    separatingTest: "Hardness test: Pocket knife scratches Lepidolite (Mohs 2.5 - 3.5) easily; Sugilite resists pocket knife completely.",
                    hardnessComparison: "Lepidolite 2.5 - 3.5 vs Sugilite 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Charoite",
                    visualDifference: "Charoite has fibrous swirling silk chatoyant patterns with black aegirine needles and higher hardness (Mohs 5 - 6).",
                    separatingTest: "Hardness & Texture: Lepidolite is composed of glistening mica flakes; Charoite is swirling fibrous rock.",
                    hardnessComparison: "Lepidolite 2.5 - 3.5 vs Charoite 5.0 - 6.0"
                ),
                Lookalike(
                    mineralName: "Muscovite (White Mica)",
                    visualDifference: "Muscovite is silvery clear to pale green/tan, lacking lithium-rich lilac purple coloration.",
                    separatingTest: "Flame Test: Lithium in lepidolite colors a torch flame bright crimson red; Muscovite does not.",
                    hardnessComparison: "Both Mohs 2.5 - 3.0"
                )
            ],
            ruleOutTests: [
                "Scaly Glistening Mica Sheets: Composed of thousands of tiny glistening, reflective lavender-purple mica flakes.",
                "Copper Penny Scratch: Readily scratched by a copper coin with light pressure."
            ],
            careWarnings: [
                "Soft (Mohs 2.5 - 3.5) and flaky: delicate sheet edges will fray if scrubbed or tumbled aggressively.",
                "Protect from harsh chemicals and ultrasonic cleaning."
            ],
            summary: "The most abundant lithium-bearing mica mineral. Prized for its soft lilac-to-lavender purple hue, sparkling micaceous pearly luster, and role in modern lithium battery extraction.",
            geologicalOrigin: "Lithium-rich granitic pegmatites associated with tourmaline, spodumene, and amblygonite.",
            rarityAndOccurrence: "Common in pegmatites; Brazil (Minas Gerais), Madagascar, USA (California Pala District), Zimbabwe."
        ))

        // ==========================================
        // 5. COLOR & FLASH (10)
        // ==========================================
        catalog.append(Mineral(
            name: "Labradorite",
            alternativeNames: ["Spectrolite (Finnish variety)", "Black Moonstone", "Labrador Spar"],
            category: .colorAndFlash,
            family: "Tectosilicates (Plagioclase Feldspar - Anorthite 50-70%)",
            chemicalFormula: "(Ca,Na)(Al,Si)₄O₈",
            crystalSystem: "Triclinic",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.68 - 2.72",
            luster: "Vitreous to pearly on cleavage faces",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at 86°",
            fracture: "Uneven to conchoidal (brittle)",
            transparency: "Translucent to Semi-opaque",
            refractiveIndex: "1.559 - 1.570",
            colorRange: ["Dark Charcoal Grey Body with Electric Blue, Peacock Green, Gold, Orange, and Violet Spectral Flash (Labradorescence)"],
            commonForms: [.cabochon, .rough, .carved, .tumbled, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Rainbow Moonstone (White Labradorite)",
                    visualDifference: "Rainbow moonstone has a milky white or translucent body; Classic labradorite has a dark charcoal/grey body.",
                    separatingTest: "Body color inspection: Labradorite is dark slate-grey/charcoal with directional flash.",
                    hardnessComparison: "Both Mohs 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Opal",
                    visualDifference: "Opal flashes floating scattered dots of light from any angle; Labradorite flashes solid sheets of color only at specific reflective angles.",
                    separatingTest: "Angular Flash Directionality: Labradorite flashes color across planar submicroscopic twin lamellae when tilted; Opal play-of-color is non-directional.",
                    hardnessComparison: "Labradorite 6.0 - 6.5 vs Opal 5.5 - 6.0"
                ),
                Lookalike(
                    mineralName: "Nuummite",
                    visualDifference: "Nuummite is ancient black metamorphic rock with radiating golden/bronze/blue iridescent needle spray flakes.",
                    separatingTest: "Habit & Texture: Nuummite has needle-spray flecks; Labradorite has continuous sheet-like Schiller planes.",
                    hardnessComparison: "Labradorite 6.0 - 6.5 vs Nuummite 5.5 - 6.0"
                )
            ],
            ruleOutTests: [
                "Directional Labradorescence Flash: Hold under light and tilt; at a precise angle, a blazing sheet of electric blue, gold, or peacock green illuminates the entire face.",
                "Twin Striations: Look closely under light for microscopic parallel razor-thin twinning lines across cleavage faces."
            ],
            careWarnings: [
                "Two cleavage planes make it vulnerable to breakage along internal planes if struck sharply.",
                "Clean with mild soap and room temperature water; avoid steam and ultrasonic cleaning."
            ],
            summary: "A plagioclase feldspar famous for 'labradorescence'—a brilliant optical phenomenon where light reflects and interferes between alternating microscopic twin lamellae layers.",
            geologicalOrigin: "Anorthosite plutonic igneous complexes and basaltic lavas.",
            rarityAndOccurrence: "Canada (Labrador Coast), Madagascar, Finland (Spectrolite), Norway, Australia."
        ))

        catalog.append(Mineral(
            name: "Fire Agate",
            alternativeNames: ["Iridescent Botryoidal Agate"],
            category: .colorAndFlash,
            family: "Quartz (Chalcedony with Limonite/Goethite)",
            chemicalFormula: "SiO₂ with thin alternating iron oxide nanosheets",
            crystalSystem: "Trigonal (microcrystalline botryoidal)",
            mohsHardness: "6.5 - 7.0",
            minHardness: 6.5,
            maxHardness: 7.0,
            specificGravity: "2.60 - 2.65",
            luster: "Vitreous to iridescent",
            streak: "White",
            cleavage: "None",
            fracture: "Conchoidal",
            transparency: "Translucent to Semi-opaque",
            refractiveIndex: "1.530 - 1.540",
            colorRange: ["Brownish-Amber Base with Fiery Iridescent Red, Gold, Green, and Purple Schiller Bubbles"],
            commonForms: [.cabochon, .rough, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Precious Opal",
                    visualDifference: "Opal is soft (Mohs 5.5 - 6) and has a white/black base; Fire agate is hard quartz (Mohs 7) with a dark brown chalcedony base and bubbly botryoidal schiller.",
                    separatingTest: "Hardness test: Pocket knife (Mohs 5.5) scratches Opal; Fire Agate (Mohs 7) scratches pocket knife steel.",
                    hardnessComparison: "Fire Agate 7.0 vs Opal 5.5"
                ),
                Lookalike(
                    mineralName: "Ammolite",
                    visualDifference: "Ammolite is fossil aragonite shell (Mohs 3.5 - 4.0) that fizzes in vinegar.",
                    separatingTest: "Acid test & Hardness: Ammolite fizzes in acid; Fire Agate is inert to acid and cannot be scratched by knife.",
                    hardnessComparison: "Fire Agate 7.0 vs Ammolite 3.5 - 4.0"
                ),
                Lookalike(
                    mineralName: "Carnelian",
                    visualDifference: "Carnelian has uniform warm orange glow without shimmering holographic botryoidal iridescence.",
                    separatingTest: "Optical effect: Fire agate has holographic rainbow interference fringes.",
                    hardnessComparison: "Both Mohs 6.5 - 7.0"
                )
            ],
            ruleOutTests: [
                "Botryoidal Bubble Iridescence: Grape-like clusters covered in holographic iridescent rainbow fringes under strong pinpoint light.",
                "Hardness: Effortlessly scratches glass and steel without scratching itself (Mohs 7.0)."
            ],
            careWarnings: [
                "Very tough and durable for everyday ring wear.",
                "Safe for water and standard jewelry cleaners."
            ],
            summary: "A rare botryoidal variety of chalcedony containing microscopic layers of goethite and limonite that produce a burning holographic iridescent rainbow 'fire'.",
            geologicalOrigin: "Tertiary volcanic rhyolite gas cavities and hot spring hydrothermal flows.",
            rarityAndOccurrence: "Rare; strictly found in the desert Southwest: USA (Arizona, California) and Northern Mexico (Aguascalientes)."
        ))

        catalog.append(Mineral(
            name: "Apatite",
            alternativeNames: ["Fluorapatite", "Neon Blue Apatite", "Asparagus Stone"],
            category: .colorAndFlash,
            family: "Phosphates (Apatite Group)",
            chemicalFormula: "Ca₅(PO₄)₃(F,Cl,OH)",
            crystalSystem: "Hexagonal (tabular and prismatic 6-sided hexagonal crystals)",
            mohsHardness: "5.0 (Mohs Baseline)",
            minHardness: 5.0,
            maxHardness: 5.0,
            specificGravity: "3.16 - 3.22",
            luster: "Vitreous to subresinous",
            streak: "White",
            cleavage: "Indistinct / poor basal {0001}",
            fracture: "Conchoidal to uneven (very brittle)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.632 - 1.646",
            colorRange: ["Neon Electric Blue", "Paraiba Teal", "Asparagus Green", "Golden Yellow", "Violet"],
            commonForms: [.rough, .cut, .cabochon, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Paraiba Tourmaline",
                    visualDifference: "Paraiba tourmaline has 3-sided triangular prisms, is much harder (Mohs 7.5), and resists pocket knife scratches.",
                    separatingTest: "Hardness test: Pocket knife or steel nail (Mohs 5.5) will scratch Apatite (Mohs 5.0); Tourmaline (Mohs 7.5) is unaffected.",
                    hardnessComparison: "Apatite 5.0 vs Tourmaline 7.5"
                ),
                Lookalike(
                    mineralName: "Beryl (Aquamarine)",
                    visualDifference: "Aquamarine is much harder (Mohs 7.5 - 8.0) and lower specific gravity (2.70).",
                    separatingTest: "Hardness: Quartz crystal (Mohs 7.0) scratches Apatite easily; Quartz cannot scratch Aquamarine.",
                    hardnessComparison: "Apatite 5.0 vs Aquamarine 7.5 - 8.0"
                ),
                Lookalike(
                    mineralName: "Fluorite",
                    visualDifference: "Fluorite has cubic crystals and 4-directional octahedral cleavage.",
                    separatingTest: "Hardness & Cleavage: Apatite (Mohs 5) scratches Fluorite (Mohs 4).",
                    hardnessComparison: "Apatite 5.0 vs Fluorite 4.0"
                )
            ],
            ruleOutTests: [
                "Mohs 5.0 Scratch Benchmark: Scratches fluorite (4.0); scratched by pocket knife steel (5.5) and quartz (7.0).",
                "Electric Neon Saturation: Intense glowing swimming-pool neon blue-green color."
            ],
            careWarnings: [
                "Soft (Mohs 5.0) and heat-sensitive: susceptible to scratches, acids, and thermal shock.",
                "Clean only with a soft damp cloth. Never use steam or ultrasonic cleaning."
            ],
            summary: "The defining mineral standard for Mohs Hardness 5.0. Celebrated in jewelry for its mind-bending electric 'Paraiba neon-blue' hues and biological role as the primary component of human bone and tooth enamel.",
            geologicalOrigin: "Granite pegmatites, carbonatites, and metamorphic calc-silicate skarns.",
            rarityAndOccurrence: "Madagascar (famous neon blue), Brazil, Mexico (Cerro de Mercado yellow), Russia (Kola Peninsula)."
        ))

        catalog.append(Mineral(
            name: "Charoite",
            alternativeNames: ["Lilac Stone", "Charoite River Stone"],
            category: .colorAndFlash,
            family: "Inosilicates / Silicate Complex",
            chemicalFormula: "(K,Sr,Ba,Mn)₁₅₋₁₆(Ca,Na)₃₂[Si₇₀(O,OH)₁₈₀](OH,F)₄·~n H₂O",
            crystalSystem: "Monoclinic (massive fibrous interlocking swirling felted aggregates)",
            mohsHardness: "5.0 - 6.0",
            minHardness: 5.0,
            maxHardness: 6.0,
            specificGravity: "2.54 - 2.68",
            luster: "Silky to pearly / vitreous",
            streak: "White",
            cleavage: "Distinct in 3 directions (obscured by interlocking fibrous felt)",
            fracture: "Splintery to uneven; exceptionally tough",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.550 - 1.559",
            colorRange: ["Vivid Swirling Lavender-Purple", "Deep Royal Violet with Silky Pearl White and Black Aegirine Feathers"],
            commonForms: [.cabochon, .carved, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Sugilite",
                    visualDifference: "Sugilite has a solid, waxy, non-fibrous deep magenta-purple color without swirling silky chatoyant ribbons.",
                    separatingTest: "Pattern & Chatoyancy: Charoite exhibits swirling silk chatoyancy; Sugilite is uniform opaque wax-like purple.",
                    hardnessComparison: "Charoite 5.0 - 6.0 vs Sugilite 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Lepidolite",
                    visualDifference: "Lepidolite is soft mica (Mohs 2.5 - 3.5) with flaky glitter scales; Charoite is tough fibrous rock.",
                    separatingTest: "Hardness test: Copper coin (Mohs 3.5) scratches Lepidolite easily; Charoite resists copper coin.",
                    hardnessComparison: "Charoite 5.5 vs Lepidolite 2.5 - 3.5"
                ),
                Lookalike(
                    mineralName: "Purple Fluorite",
                    visualDifference: "Fluorite has cubic cleavage steps and lacks silky swirling fibrous texture.",
                    separatingTest: "Hardness & Cleavage: Fluorite is softer (Mohs 4) and cleaves into octahedrons.",
                    hardnessComparison: "Charoite 5.5 vs Fluorite 4.0"
                )
            ],
            ruleOutTests: [
                "Swirling Silky Fibrous Marbling: Intricate swirls of purple, violet, pearl-white chatoyant silk fibers, and black acicular needles of aegirine.",
                "Copper Penny Scratch: Cannot be scratched by copper penny (Mohs 3.5)."
            ],
            careWarnings: [
                "Tough and resilient for daily jewelry wear.",
                "Clean with warm soapy water; avoid harsh chemical solvents."
            ],
            summary: "A rare, complex silicate found in only one single river basin on Earth in Siberia. Prized for its swirling, marble-like lavender ribbons and silky pearl chatoyancy.",
            geologicalOrigin: "Metasomatic alteration of limestone and alkaline syenite intrusions in the Murun Massif.",
            rarityAndOccurrence: "Extremely rare; found ONLY along the Chara River in the Sakha Republic (Siberia, Russia)."
        ))

        catalog.append(Mineral(
            name: "Prehnite",
            alternativeNames: ["Cape Emerald", "Grape Prehnite", "Epidote-in-Prehnite"],
            category: .colorAndFlash,
            family: "Phyllosilicates / Inosilicates",
            chemicalFormula: "Ca₂Al(AlSi₃O₁₀)(OH)₂",
            crystalSystem: "Orthorhombic (globular, botryoidal, barrel-shaped aggregates)",
            mohsHardness: "6.0 - 6.5",
            minHardness: 6.0,
            maxHardness: 6.5,
            specificGravity: "2.80 - 2.95",
            luster: "Vitreous to pearly / waxy",
            streak: "White",
            cleavage: "Distinct in 1 direction {001}",
            fracture: "Uneven to conchoidal",
            transparency: "Translucent to Semi-transparent",
            refractiveIndex: "1.611 - 1.665",
            colorRange: ["Luminous Apple Green", "Pale Mint Green", "Yellow-Green", "Translucent Olive with Black/Green Epidote Inclusions"],
            commonForms: [.rough, .cabochon, .tumbled, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Chrysoprase",
                    visualDifference: "Chrysoprase is microcrystalline quartz (Mohs 7.0) with uniform nickel green color and conchoidal fracture.",
                    separatingTest: "Hardness test: Quartz crystal scratches Prehnite (Mohs 6.0 - 6.5); cannot scratch Chrysoprase (Mohs 7.0).",
                    hardnessComparison: "Prehnite 6.0 - 6.5 vs Chrysoprase 7.0"
                ),
                Lookalike(
                    mineralName: "Jade (Nephrite / Jadeite)",
                    visualDifference: "Jade has higher toughness, greasy luster, and lacks botryoidal spherical formations.",
                    separatingTest: "Refractive index: Jadeite RI is 1.66; Nephrite RI is 1.61; Prehnite displays unique glowing translucency.",
                    hardnessComparison: "Prehnite 6.0 - 6.5 vs Jade 6.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Green Grossular Garnet",
                    visualDifference: "Garnet is isotropic and denser (SG 3.6).",
                    separatingTest: "Specific gravity: Grossular sinks much faster in heavy liquids.",
                    hardnessComparison: "Prehnite 6.0 - 6.5 vs Garnet 7.0 - 7.5"
                )
            ],
            ruleOutTests: [
                "Glowing Translucent Apple Green: Soft glowing gelatinous translucency often featuring dark needle-like inclusions of epidote.",
                "Botryoidal Habit: Rounded bubbly grape-like clusters in rough specimens."
            ],
            careWarnings: [
                "Durable for jewelry; safe in warm soapy water.",
                "Avoid exposure to hydrochloric acid."
            ],
            summary: "A calcium aluminum silicate named after Dutch military commander Colonel Hendrik von Prehn in 1788 (the first mineral named after a historical person). Celebrated for its glowing apple-green translucency.",
            geologicalOrigin: "Hydrothermal secondary mineral in basalt volcanic cavities and zeolitic fissures.",
            rarityAndOccurrence: "South Africa (Karoo), Mali (superb gem crystals with epidote), Australia, USA (New Jersey Paterson traps)."
        ))

        catalog.append(Mineral(
            name: "Larimar",
            alternativeNames: ["Blue Pectolite", "Dolphin Stone", "Atlantis Stone"],
            category: .colorAndFlash,
            family: "Inosilicates (Pectolite Group)",
            chemicalFormula: "NaCa₂Si₃O₈(OH) with trace Cu²⁺ substitution for Ca²⁺",
            crystalSystem: "Triclinic (compact fibrous radiating needle sprays)",
            mohsHardness: "4.5 - 5.0",
            minHardness: 4.5,
            maxHardness: 5.0,
            specificGravity: "2.74 - 2.88",
            luster: "Vitreous to silky on cleavages",
            streak: "White",
            cleavage: "Perfect in 2 directions meeting at 84°",
            fracture: "Uneven to splintery",
            transparency: "Translucent to Semi-opaque",
            refractiveIndex: "1.599 - 1.628",
            colorRange: ["Caribbean Ocean Blue", "Sky Blue", "Cyan-Turquoise with White Radiating Wave Patterns", "Mint Green undertones"],
            commonForms: [.cabochon, .rough, .tumbled, .carved],
            topLookalikes: [
                Lookalike(
                    mineralName: "Amazonite",
                    visualDifference: "Amazonite has grid-like albite perthite stripes and higher hardness (Mohs 6 - 6.5).",
                    separatingTest: "Hardness test: Pocket knife (Mohs 5.5) will NOT scratch Amazonite; Larimar (Mohs 4.5 - 5.0) is scratched by a knife.",
                    hardnessComparison: "Larimar 4.5 - 5.0 vs Amazonite 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Hemimorphite",
                    visualDifference: "Hemimorphite is zinc silicate (Mohs 5.0) with tabular crystal habits and higher density (SG 3.4).",
                    separatingTest: "Specific gravity: Hemimorphite is significantly denser (SG 3.4) than Larimar (SG 2.8).",
                    hardnessComparison: "Larimar 4.5 - 5.0 vs Hemimorphite 5.0"
                ),
                Lookalike(
                    mineralName: "Dyed Howlite / Magnesite",
                    visualDifference: "Dyed howlite has black spiderweb veins rather than white radiating ocean wave patterns.",
                    separatingTest: "Acetone test: Swab with acetone bleeds blue dye on imitation stones; Larimar copper color is 100% natural and insoluble.",
                    hardnessComparison: "Larimar 4.5 - 5.0 vs Howlite 3.5"
                )
            ],
            ruleOutTests: [
                "Caribbean Sunlit Swimming Pool Pattern: Radiating needle-spray fibrous patterns resembling sunlight dancing through turquoise tropical ocean water.",
                "Knife Scratch: Pocket knife blade (Mohs 5.5) produces a light scratch on an unpolished edge."
            ],
            careWarnings: [
                "Photosensitive: prolonged direct sunlight or extreme UV exposure can cause blue color to gradually fade to pale grey.",
                "Soft (Mohs 4.5 - 5): protect from scratches, cosmetics, and ultrasonic cleaning."
            ],
            summary: "A breathtaking copper-colored variety of pectolite found exclusively in one remote mountain valley in the Dominican Republic. Its swirling blue-and-white patterns mirror the Caribbean sea.",
            geologicalOrigin: "Hydrothermal precipitation of copper-bearing pectolite needles in basalt gas cavities.",
            rarityAndOccurrence: "Extremely rare single-source locality: Barahona Province, Dominican Republic."
        ))

        catalog.append(Mineral(
            name: "Serpentine",
            alternativeNames: ["Bowenite (Hard gem variety)", "Williamsite", "New Jade (misnomer)", "Lizardite / Antigorite / Chrysotile"],
            category: .colorAndFlash,
            family: "Phyllosilicates (Serpentine Subgroup)",
            chemicalFormula: "(Mg,Fe)₃Si₂O₅(OH)₄",
            crystalSystem: "Monoclinic / Orthorhombic (microcrystalline massive, fibrous, foliated)",
            mohsHardness: "3.0 - 5.0 (Bowenite variety up to 5.5)",
            minHardness: 3.0,
            maxHardness: 5.0,
            specificGravity: "2.44 - 2.65",
            luster: "Greasy, waxy, to silky",
            streak: "White",
            cleavage: "None in massive forms",
            fracture: "Conchoidal to splintery",
            transparency: "Translucent to Opaque",
            refractiveIndex: "1.560 - 1.571",
            colorRange: ["Serpent Mottled Olive Green", "Yellowish-Green", "Chartreuse", "Blackish-Green with Veins"],
            commonForms: [.carved, .cabochon, .rough, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Nephrite Jade",
                    visualDifference: "Nephrite is significantly harder (Mohs 6.0 - 6.5) and much tougher.",
                    separatingTest: "Hardness test: Pocket knife (Mohs 5.5) scratches Serpentine easily; Pocket knife blade cannot scratch Nephrite Jade.",
                    hardnessComparison: "Serpentine 3.5 - 5.0 vs Nephrite Jade 6.0 - 6.5"
                ),
                Lookalike(
                    mineralName: "Prehnite",
                    visualDifference: "Prehnite is harder (Mohs 6.0 - 6.5) with vitreous luster and higher refractive index (1.63).",
                    separatingTest: "Hardness & Luster: Serpentine has greasy/waxy feel; Prehnite is vitreous and harder.",
                    hardnessComparison: "Serpentine 3.5 - 5.0 vs Prehnite 6.5"
                ),
                Lookalike(
                    mineralName: "Talc (Soapstone)",
                    visualDifference: "Talc is extremely soft (Mohs 1.0) and scratches with a fingernail.",
                    separatingTest: "Fingernail scratch: Serpentine resists fingernail scratch (Mohs 2.5); Talc scratches effortlessly.",
                    hardnessComparison: "Serpentine 3.5 - 5.0 vs Talc 1.0"
                )
            ],
            ruleOutTests: [
                "Greasy Tactile Feel: Waxy to greasy surface texture with mottled 'snake-skin' dark and light green color patches.",
                "Pocket Knife Scratch: Scratched by a steel blade (Mohs 5.5) with moderate pressure."
            ],
            careWarnings: [
                "Do not soak in acids which dissolve magnesium content.",
                "Safe for gentle water washing and carving."
            ],
            summary: "A magnesium phyllosilicate named for its resemblance to mottled green serpent snakeskin. Extensively carved as ornamental art and historically termed 'New Jade'.",
            geologicalOrigin: "Hydrothermal hydration and metamorphism of mantle peridotites (serpentinization).",
            rarityAndOccurrence: "Abundant; USA (California state rock), New Zealand, China, Italy, Afghanistan."
        ))

        catalog.append(Mineral(
            name: "Aragonite",
            alternativeNames: ["Aragonite Sputnik", "Cave Coral (Flos Ferri)", "Tazouta Aragonite"],
            category: .colorAndFlash,
            family: "Carbonates",
            chemicalFormula: "CaCO₃ (High-pressure orthorhombic polymorph of Calcite)",
            crystalSystem: "Orthorhombic (pseudohexagonal cyclic penetration twins 'sputniks', radiating acicular sprays)",
            mohsHardness: "3.5 - 4.0",
            minHardness: 3.5,
            maxHardness: 4.0,
            specificGravity: "2.93 - 2.95",
            luster: "Vitreous to resinous",
            streak: "White",
            cleavage: "Distinct in 1 direction {010}, imperfect in {110}",
            fracture: "Subconchoidal (brittle)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.530 - 1.685 (Extreme Birefringence 0.155)",
            colorRange: ["Amber Orange", "Red-Brown", "White", "Clear Colorless", "Cyan Blue (Chinese / Italian variety)"],
            commonForms: [.rough, .carved, .tumbled],
            topLookalikes: [
                Lookalike(
                    mineralName: "Calcite",
                    visualDifference: "Calcite has rhombohedral cleavage steps and forms scalenohedrons; Aragonite forms 6-sided pseudohexagonal twin pillars ('sputniks') and needles.",
                    separatingTest: "Feigl's Solution Test / Density: Aragonite is slightly harder (Mohs 3.5 - 4.0) and denser (SG 2.94) than calcite (Mohs 3.0, SG 2.71).",
                    hardnessComparison: "Aragonite 3.5 - 4.0 vs Calcite 3.0",
                    diagnosticReaction: "Both fizz violently in vinegar; Aragonite turns black in boiling cobalt nitrate solution (Meigen's test)."
                ),
                Lookalike(
                    mineralName: "Cerussite",
                    visualDifference: "Cerussite is lead carbonate (SG 6.5) and is extraordinarily heavy.",
                    separatingTest: "Heft: Cerussite is more than twice as heavy as aragonite.",
                    hardnessComparison: "Aragonite 3.5 - 4.0 vs Cerussite 3.0 - 3.5"
                ),
                Lookalike(
                    mineralName: "Gypsum",
                    visualDifference: "Gypsum is scratched by fingernail (Mohs 2.0) and does not react to acid.",
                    separatingTest: "Fingernail & Acid: Aragonite cannot be scratched by fingernail and fizzes in vinegar.",
                    hardnessComparison: "Aragonite 3.5 - 4.0 vs Gypsum 2.0"
                )
            ],
            ruleOutTests: [
                "Cyclic Sputnik Twin Habit: Distinctive 6-sided wheel clusters radiating outward in all directions like a satellite.",
                "Acid Effervescence: Place one droplet of vinegar on sample; vigorous bubbling of CO₂ gas confirms carbonate."
            ],
            careWarnings: [
                "Acid sensitive: keep away from vinegar, citrus, and chemical cleansers.",
                "Metastable at room temperature (will slowly convert to calcite over geological millions of years)."
            ],
            summary: "The orthorhombic polymorph of calcium carbonate (CaCO₃). Famous for its iconic multi-armed amber 'sputnik' starburst clusters, cave coral formations, and as the mother-of-pearl nacre in seashells.",
            geologicalOrigin: "Low-temperature hydrothermal hot spring deposits, evaporite beds, and biological mollusk shells.",
            rarityAndOccurrence: "Spain (Molina de Aragon - type locality), Morocco (Tazouta sputniks), Italy (Sicily), Mexico."
        ))

        catalog.append(Mineral(
            name: "Celestite",
            alternativeNames: ["Celestine", "Strontium Sulfate"],
            category: .colorAndFlash,
            family: "Sulfates (Barite Group)",
            chemicalFormula: "SrSO₄",
            crystalSystem: "Orthorhombic (tabular, elongated prismatic crystals and geode clusters)",
            mohsHardness: "3.0 - 3.5",
            minHardness: 3.0,
            maxHardness: 3.5,
            specificGravity: "3.96 - 4.00 (Heavy)",
            luster: "Vitreous, pearly on cleavages",
            streak: "White",
            cleavage: "Perfect in 1 direction {001}, good in {210}",
            fracture: "Uneven (very brittle)",
            transparency: "Transparent to Translucent",
            refractiveIndex: "1.622 - 1.631",
            colorRange: ["Heavenly Sky Blue", "Ice Blue", "Pale Grey-Blue", "White", "Colorless"],
            commonForms: [.geode, .rough, .cut],
            topLookalikes: [
                Lookalike(
                    mineralName: "Barite",
                    visualDifference: "Barite is barium sulfate with higher density (SG 4.5) and is usually white, golden, or honey colored.",
                    separatingTest: "Flame Test: Celestite burns with a brilliant crimson-red flame (strontium); Barite burns pale apple-green (barium).",
                    hardnessComparison: "Both Mohs 3.0 - 3.5",
                    diagnosticReaction: "Strontium flame test confirms intense crimson-red emission."
                ),
                Lookalike(
                    mineralName: "Aquamarine (Beryl)",
                    visualDifference: "Aquamarine forms 6-sided hexagonal prisms, is hard (Mohs 7.5 - 8), and is much lighter.",
                    separatingTest: "Hardness test: Celestite (Mohs 3 - 3.5) is scratched by a copper coin; Aquamarine cannot be scratched by steel.",
                    hardnessComparison: "Celestite 3.0 - 3.5 vs Aquamarine 7.5 - 8.0"
                ),
                Lookalike(
                    mineralName: "Blue Calcite",
                    visualDifference: "Blue calcite has 75° rhombohedral cleavage and fizzes in vinegar.",
                    separatingTest: "Acid reaction & Cleavage: Blue calcite fizzes in acid; Celestite is a sulfate and does not react to vinegar.",
                    hardnessComparison: "Celestite 3.5 vs Calcite 3.0"
                )
            ],
            ruleOutTests: [
                "Crimson Flame Test: A tiny powdered grain placed on wire in gas flame burns intense crimson-red (strontium).",
                "Heft Check: Feels unexpectedly dense and heavy for a pale blue crystal (SG 3.98).",
                "Non-reactive to Vinegar: Zero bubbling when exposed to dilute acid (separates from blue calcite)."
            ],
            careWarnings: [
                "Fragile and brittle (Mohs 3 - 3.5) with perfect cleavage: protect geode points from impacts.",
                "Water soluble over time; do not soak in water baths or use ultrasonic cleaners."
            ],
            summary: "Named from Latin 'caelestis' (celestial / heavenly) for its sublime sky-blue color. A strontium sulfate mineral famed for giant glittering crystal geodes and firework pyrotechnics.",
            geologicalOrigin: "Sedimentary marine evaporites, cavity fillings in limestone and dolomites.",
            rarityAndOccurrence: "Madagascar (Sakoany - source of world's premier sky-blue geodes), USA (Ohio Lake Erie caves), Poland."
        ))

        catalog.append(Mineral(
            name: "Vivianite",
            alternativeNames: ["Blue Iron Earth", "Disthene lookalike"],
            category: .colorAndFlash,
            family: "Phosphates (Vivianite Group)",
            chemicalFormula: "Fe²⁺₃(PO₄)₂·8H₂O",
            crystalSystem: "Monoclinic (prismatic, bladed crystals, radiating starburst sprays)",
            mohsHardness: "1.5 - 2.0",
            minHardness: 1.5,
            maxHardness: 2.0,
            specificGravity: "2.67 - 2.71",
            luster: "Vitreous to pearly on cleavage faces",
            streak: "Colorless when fresh, rapidly oxidizes to dark blue / indigo powder",
            cleavage: "Perfect in 1 direction {010}, flexible and sectile",
            fracture: "Splintery to fibrous",
            transparency: "Transparent when fresh, rapidly turning Deep Translucent Indigo upon light exposure",
            refractiveIndex: "1.580 - 1.636 (Intense Pleochroism)",
            colorRange: ["Clear Colorless (when fresh underground)", "Vivid Emerald Green", "Deep Midnight Indigo Blue", "Blackish Blue"],
            commonForms: [.rough, .geode],
            topLookalikes: [
                Lookalike(
                    mineralName: "Kyanite",
                    visualDifference: "Kyanite is much harder (Mohs 4.5 - 7.0), does not change color in light, and occurs in metamorphic schists.",
                    separatingTest: "Hardness test: Vivianite (Mohs 1.5 - 2.0) is scratched by a fingernail; Kyanite resists fingernail completely.",
                    hardnessComparison: "Vivianite 2.0 vs Kyanite 4.5 - 7.0"
                ),
                Lookalike(
                    mineralName: "Azurite",
                    visualDifference: "Azurite is carbonate (Mohs 3.5 - 4) that fizzes in acid and has light blue streak.",
                    separatingTest: "Hardness & Acid: Vivianite is soft enough to scratch with fingernail and is non-carbonate.",
                    hardnessComparison: "Vivianite 2.0 vs Azurite 3.5 - 4.0"
                ),
                Lookalike(
                    mineralName: "Tourmaline (Indicolite)",
                    visualDifference: "Tourmaline is hard (Mohs 7.5) with 3-sided triangular crystal habit.",
                    separatingTest: "Hardness test: Vivianite is Mohs 2; Indicolite is Mohs 7.5.",
                    hardnessComparison: "Vivianite 2.0 vs Tourmaline 7.5"
                )
            ],
            ruleOutTests: [
                "Fingernail Scratch: So soft that a gentle stroke with your thumbnail leaves a clear indentation (Mohs 1.5 - 2.0).",
                "Photo-Oxidation Phenomenon: Freshly exposed clear/green crystal darkens to deep indigo blue when exposed to ambient room light.",
                "Extreme Pleochroism: Rotates from deep blue to apple green to colorless under polarized light."
            ],
            careWarnings: [
                "PHOTO-SENSITIVE: Keep in darkness! Prolonged light exposure oxidizes Fe²⁺ to Fe³⁺, turning transparent gems opaque dark black and brittle.",
                "Extremely fragile (Mohs 2.0): store in lightproof display containers."
            ],
            summary: "A fascinating hydrated iron phosphate that is water-clear when mined underground, but rapidly transforms into a gorgeous deep emerald-green and indigo-blue as light oxidizes its iron atoms.",
            geologicalOrigin: "Secondary alteration of primary iron-manganese phosphates in pegmatites, fossil beds, and bog iron ores.",
            rarityAndOccurrence: "Bolivia (Huanuni Mine - world's finest transparent blades), Brazil, Cameroon, USA (Idaho, Maryland)."
        ))

        return catalog
    }
}
