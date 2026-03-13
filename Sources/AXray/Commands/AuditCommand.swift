import ArgumentParser
import ApplicationServices
import Foundation

struct AuditCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "audit",
        abstract: "Audit a running app for accessibility gaps and label mismatches."
    )

    @Argument(help: "App name or bundle identifier.")
    var app: String

    @Option(name: .shortAndLong, help: "Maximum tree depth to traverse.")
    var depth: Int = 4

    @Flag(name: .long, help: "Output as JSON.")
    var json: Bool = false

    func run() async throws {
        guard let root = AppResolver.findRunningApp(app) else {
            throw ValidationError("App '\(app)' not found. Is it running?")
        }

        let rootElement = AXElement(element: root)
        var issues: [AuditIssue] = []

        await auditElement(rootElement, maxDepth: depth, issues: &issues)

        if issues.isEmpty {
            print("No accessibility issues found. All elements with visual text have matching AX labels.")
            return
        }

        print("Found \(issues.count) accessibility issue(s):\n")

        if json {
            try JSONOutput.printJSON(issues)
        } else {
            for (i, issue) in issues.enumerated() {
                let kind = issue.kind == .accessibilityGap ? "ACCESSIBILITY GAP" : "LABEL MISMATCH"
                let role = issue.role ?? "Unknown"
                print("[\(i + 1)] \(kind) — \(role)")
                if !issue.axText.isEmpty {
                    print("    AX text: \"\(issue.axText)\"")
                }
                print("    Vision text: \"\(issue.visionText)\"")
                if let f = issue.frame {
                    print("    Frame: (\(Int(f.x)),\(Int(f.y))) \(Int(f.width))x\(Int(f.height))")
                }
                print()
            }
        }
    }
}

private func auditElement(
    _ element: AXElement,
    maxDepth: Int,
    issues: inout [AuditIssue],
    currentDepth: Int = 0
) async {
    guard currentDepth <= maxDepth else { return }

    let axText = element.axText

    // Only analyze elements with a visible frame
    if let frame = element.frame, frame.width > 20, frame.height > 20,
       let image = ScreenCapture.captureElement(element) {
        let visionResult = await VisionPipeline.analyzeImage(image)

        if !visionResult.isEmpty {
            if axText.isEmpty {
                // Vision sees text but AX knows nothing
                issues.append(AuditIssue(
                    kind: .accessibilityGap,
                    role: element.role,
                    axText: "",
                    visionText: visionResult.combinedText,
                    frame: CodableRect(frame),
                    depth: currentDepth
                ))
            } else {
                // Both have text — check for mismatch
                let axLower = axText.lowercased()
                let visionLower = visionResult.combinedText.lowercased()
                if !axLower.contains(visionLower) && !visionLower.contains(axLower) {
                    issues.append(AuditIssue(
                        kind: .labelMismatch,
                        role: element.role,
                        axText: axText,
                        visionText: visionResult.combinedText,
                        frame: CodableRect(frame),
                        depth: currentDepth
                    ))
                }
            }
        }
    }

    for child in element.children {
        await auditElement(child, maxDepth: maxDepth, issues: &issues, currentDepth: currentDepth + 1)
    }
}
