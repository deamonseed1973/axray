import Foundation

/// Pretty-prints an augmented AX tree to stdout.
enum TreePrinter {
    static func printTree(_ element: AugmentedElement, indent: Int = 0) {
        let prefix = String(repeating: "  ", count: indent)
        let role = element.role ?? "Unknown"

        var line = "\(prefix)\(role)"

        if !element.axText.isEmpty {
            line += "  \"\(element.axText)\""
        }

        if let vision = element.visionResult, !vision.isEmpty {
            line += "  [Vision: \"\(vision.combinedText)\"]"
        }

        if let frame = element.frame {
            line += "  (\(Int(frame.x)),\(Int(frame.y)) \(Int(frame.width))x\(Int(frame.height)))"
        }

        if element.hasAccessibilityGap {
            line += "  ⚠️ ACCESSIBILITY GAP"
        } else if element.hasLabelMismatch {
            line += "  ⚠️ LABEL MISMATCH"
        }

        print(line)

        for child in element.children {
            printTree(child, indent: indent + 1)
        }
    }
}
