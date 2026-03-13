import ArgumentParser

@main
struct AXray: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "axray",
        abstract: "AXray — augment macOS accessibility trees with Vision-detected visual text.",
        discussion: """
            AXray walks the accessibility tree of any running macOS app, captures a \
            screenshot of each UI element's screen bounds, and runs a Vision pipeline \
            on that screenshot. The result is an augmented accessibility tree: AX \
            structural data enriched with visually-detected text.
            """,
        version: "0.1.0",
        subcommands: [InspectCommand.self, FindCommand.self, AuditCommand.self]
    )
}
