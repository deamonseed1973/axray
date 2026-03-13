import ArgumentParser
import ApplicationServices
import Foundation

struct InspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Dump the augmented accessibility tree of a running app."
    )

    @Argument(help: "App name or bundle identifier.")
    var app: String

    @Option(name: .shortAndLong, help: "Maximum tree depth to traverse.")
    var depth: Int = 4

    @Flag(name: .long, help: "Run Vision analysis on elements lacking AX text.")
    var vision: Bool = false

    @Flag(name: .long, help: "Output as JSON.")
    var json: Bool = false

    func run() async throws {
        guard let root = AppResolver.findRunningApp(app) else {
            throw ValidationError("App '\(app)' not found. Is it running?")
        }

        let rootElement = AXElement(element: root)
        let augmented = await buildAugmentedTree(from: rootElement, maxDepth: depth, useVision: vision)

        if json {
            try JSONOutput.printJSON(augmented)
        } else {
            TreePrinter.printTree(augmented)
        }
    }
}

/// Build an augmented tree by walking the AX tree and optionally running Vision.
func buildAugmentedTree(
    from element: AXElement,
    maxDepth: Int,
    useVision: Bool,
    currentDepth: Int = 0
) async -> AugmentedElement {
    var visionResult: VisionResult?

    if useVision {
        let text = element.axText
        let frame = element.frame
        // Run Vision on elements that have no AX text and a reasonable frame
        if text.isEmpty,
           let f = frame, f.width > 20, f.height > 20,
           let image = ScreenCapture.captureElement(element) {
            visionResult = await VisionPipeline.analyzeImage(image)
        }
    }

    var childElements: [AugmentedElement] = []
    if currentDepth < maxDepth {
        for child in element.children {
            let augChild = await buildAugmentedTree(
                from: child,
                maxDepth: maxDepth,
                useVision: useVision,
                currentDepth: currentDepth + 1
            )
            childElements.append(augChild)
        }
    }

    return AugmentedElement(
        role: element.role,
        title: element.title,
        value: element.value,
        label: element.label,
        identifier: element.identifier,
        axText: element.axText,
        frame: element.frame.map { CodableRect($0) },
        visionResult: visionResult,
        depth: currentDepth,
        children: childElements
    )
}
