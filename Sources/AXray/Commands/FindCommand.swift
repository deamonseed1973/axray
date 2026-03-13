import ArgumentParser
import ApplicationServices
import Foundation

struct FindCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "find",
        abstract: "Find elements containing specific text in a running app."
    )

    @Argument(help: "App name or bundle identifier.")
    var app: String

    @Argument(help: "Text to search for (case-insensitive).")
    var query: String

    @Option(name: .shortAndLong, help: "Maximum tree depth to traverse.")
    var depth: Int = 6

    @Flag(name: .long, help: "Also search Vision-detected text.")
    var vision: Bool = false

    @Flag(name: .long, help: "Output as JSON.")
    var json: Bool = false

    func run() async throws {
        guard let root = AppResolver.findRunningApp(app) else {
            throw ValidationError("App '\(app)' not found. Is it running?")
        }

        let rootElement = AXElement(element: root)
        var matches: [AugmentedElement] = []
        let queryLower = query.lowercased()

        await findMatches(
            in: rootElement,
            query: queryLower,
            maxDepth: depth,
            useVision: vision,
            matches: &matches
        )

        if matches.isEmpty {
            print("No elements found matching '\(query)'.")
            return
        }

        print("Found \(matches.count) matching element(s):\n")

        if json {
            try JSONOutput.printJSON(matches)
        } else {
            for (i, match) in matches.enumerated() {
                let role = match.role ?? "Unknown"
                print("[\(i + 1)] \(role)")
                if !match.axText.isEmpty {
                    print("    AX: \"\(match.axText)\"")
                }
                if let vision = match.visionResult, !vision.isEmpty {
                    print("    Vision: \"\(vision.combinedText)\"")
                }
                if let f = match.frame {
                    print("    Frame: (\(Int(f.x)),\(Int(f.y))) \(Int(f.width))x\(Int(f.height))")
                }
                print()
            }
        }
    }
}

private func findMatches(
    in element: AXElement,
    query: String,
    maxDepth: Int,
    useVision: Bool,
    matches: inout [AugmentedElement],
    currentDepth: Int = 0
) async {
    guard currentDepth <= maxDepth else { return }

    let axText = element.axText
    var visionResult: VisionResult?
    var matched = axText.lowercased().contains(query)

    if useVision, !matched,
       let frame = element.frame, frame.width > 10, frame.height > 10,
       let image = ScreenCapture.captureElement(element) {
        let result = await VisionPipeline.analyzeImage(image)
        visionResult = result
        if result.combinedText.lowercased().contains(query) {
            matched = true
        }
    }

    if matched {
        let augmented = AugmentedElement(
            role: element.role,
            title: element.title,
            value: element.value,
            label: element.label,
            identifier: element.identifier,
            axText: axText,
            frame: element.frame.map { CodableRect($0) },
            visionResult: visionResult,
            depth: currentDepth,
            children: []
        )
        matches.append(augmented)
    }

    for child in element.children {
        await findMatches(
            in: child,
            query: query,
            maxDepth: maxDepth,
            useVision: useVision,
            matches: &matches,
            currentDepth: currentDepth + 1
        )
    }
}
