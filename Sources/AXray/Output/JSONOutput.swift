import Foundation

/// JSON output for augmented AX tree data.
enum JSONOutput {
    static func printJSON(_ element: AugmentedElement) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(element)
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    static func printJSON(_ elements: [AugmentedElement]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(elements)
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    static func printJSON(_ issues: [AuditIssue]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(issues)
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
}

/// An issue discovered during an accessibility audit.
struct AuditIssue: Codable {
    enum IssueKind: String, Codable {
        case accessibilityGap = "accessibility_gap"
        case labelMismatch = "label_mismatch"
    }

    let kind: IssueKind
    let role: String?
    let axText: String
    let visionText: String
    let frame: CodableRect?
    let depth: Int
}
