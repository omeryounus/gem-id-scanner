import SwiftUI

/// Shared legal document viewer for Terms of Service and Privacy Policy.
public struct LegalDocumentView: View {
    public let title: String
    public let content: String
    
    @Environment(\.dismiss) private var dismiss
    
    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(4)
            }
            .padding(20)
        }
        .background(Color(red: 0.07, green: 0.08, blue: 0.11).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundColor(.amberGold)
            }
        }
    }
}

/// Standardized legal text contents.
public enum LegalDocumentContent {
    public static let terms = """
    GEM ID SCANNER — TERMS OF SERVICE
    Last Updated: October 2026

    1. ACCEPTANCE OF TERMS
    By downloading or using Field Bench ("the App"), you agree to these Terms. If you do not agree, do not use the App.

    2. GEMOLOGICAL DISCLAIMER — ADVISORY ONLY
    Field Bench provides non-destructive optical suggestions based on visual features and multimodal AI. Visual identification alone CANNOT guarantee gemological authenticity. Always confirm valuable minerals using standardized physical tests (refractive index, specific gravity, Mohs hardness) performed by certified gemological laboratories.

    3. SUBSCRIPTIONS & IN-APP PURCHASES
    Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current billing cycle in your Apple ID account settings.

    4. USER FEEDBACK & CONTRIBUTIONS
    Ground-truth corrections submitted with explicit user consent are used to verify and improve catalog accuracy.
    """

    public static let privacy = """
    GEM ID SCANNER — PRIVACY POLICY
    Last Updated: November 2026

    1. ON-DEVICE PROCESSING FIRST
    Specimen color analysis and collection storage run entirely on-device using local storage.

    2. HYBRID IDENTIFICATION
    Each scan sends the photograph to Gemini through Firebase AI Logic. Apple Intelligence may also rank the measured color on this iPhone, and that rank is used only when Gemini does not return one.

    3. BETA MODEL IMPROVEMENT OPT-IN
    Contributing corrections is optional and defaults to OFF. When it is on, the app signs in anonymously and uploads labels only: the predicted names, your correction, and a prompt hash. Specimen photos are not included.

    4. DATA DELETION
    You can clear cached data or delete your local collection at any time in App Settings.
    """
}
