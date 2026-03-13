import Foundation

/// Result of Vision analysis on an element's screenshot.
struct VisionResult: Codable {
    let text: [String]
    let barcodes: [String]

    var combinedText: String {
        (text + barcodes).joined(separator: " ")
    }

    var isEmpty: Bool {
        text.isEmpty && barcodes.isEmpty
    }

    static let empty = VisionResult(text: [], barcodes: [])
}

/// An AX element augmented with Vision analysis data.
struct AugmentedElement: Codable {
    let role: String?
    let title: String?
    let value: String?
    let label: String?
    let identifier: String?
    let axText: String
    let frame: CodableRect?
    let visionResult: VisionResult?
    let depth: Int
    let children: [AugmentedElement]

    /// Whether Vision found text that AX doesn't know about.
    var hasAccessibilityGap: Bool {
        guard let vision = visionResult, !vision.isEmpty else { return false }
        return axText.isEmpty
    }

    /// Whether AX label significantly differs from Vision-detected text.
    var hasLabelMismatch: Bool {
        guard let vision = visionResult, !vision.combinedText.isEmpty else { return false }
        guard !axText.isEmpty else { return false }
        let axLower = axText.lowercased()
        let visionLower = vision.combinedText.lowercased()
        // If neither contains the other, it's a mismatch
        return !axLower.contains(visionLower) && !visionLower.contains(axLower)
    }
}

/// CGRect wrapper that conforms to Codable.
struct CodableRect: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}
