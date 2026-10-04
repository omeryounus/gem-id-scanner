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
    By downloading or using Gem ID Scanner ("the App"), you agree to these Terms. If you do not agree, do not use the App.

    2. GEMOLOGICAL DISCLAIMER — ADVISORY ONLY
    Gem ID Scanner provides non-destructive optical suggestions based on visual features and multimodal AI. Visual identification alone CANNOT guarantee gemological authenticity. Always confirm valuable minerals using standardized physical tests (refractive index, specific gravity, Mohs hardness) performed by certified gemological laboratories.

    3. SUBSCRIPTIONS & IN-APP PURCHASES
    Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current billing cycle in your Apple ID account settings.

    4. USER FEEDBACK & CONTRIBUTIONS
    Ground-truth corrections submitted with explicit user consent are used to verify and improve catalog accuracy.
    """

    public static let privacy = """
    GEM ID SCANNER — PRIVACY POLICY
    Last Updated: October 2026

    1. ON-DEVICE PROCESSING FIRST
    Specimen color analysis and collection storage run entirely on-device using local storage.

    2. MULTIMODAL VISION AI
    When High-Precision Multimodal AI is active, specimen images are securely sent to Google Gemini API for second-opinion visual analysis.

    3. BETA MODEL IMPROVEMENT OPT-IN
    Contributing specimen corrections to model improvement is entirely optional and defaults to OFF. Images and diagnostic feedback are only shared when explicitly opted in by the user.

    4. DATA DELETION
    You can clear cached data or delete your local collection at any time in App Settings.
    """
}
