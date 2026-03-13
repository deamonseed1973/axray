# AXray

**Augment macOS accessibility trees with Vision-detected visual text.**

AXray walks the accessibility tree of any running macOS app, captures a screenshot of each UI element's screen bounds, and runs Apple's Vision framework on that screenshot. The result is an *augmented* accessibility tree — AX structural data enriched with visually-detected text that the accessibility API does not know about.

## The Problem

macOS accessibility APIs expose a tree of UI elements with roles, labels, titles, and values. But many apps have gaps: buttons with images but no label, custom views with rendered text that AX can't see, or labels that don't match what's visually displayed. These gaps make apps harder to automate and less accessible.

AXray bridges this gap by combining what the accessibility API *reports* with what Vision *sees*.

## The Chimera

AXray is inspired by two open-source projects:

- **[AXorcist](https://github.com/steipete/AXorcist)** — The visitor-pattern tree traversal engine, cycle detection via `CFHash`, and the approach to wrapping `AXUIElement` with typed attribute accessors all come from AXorcist's sophisticated AX tree walking design.

- **[Viz](https://github.com/alienator88/Viz)** — The technique of running multiple Vision requests (`VNRecognizeTextRequest` + `VNDetectBarcodesRequest`) in parallel on a single `VNImageRequestHandler` comes from Viz's efficient screenshot analysis pipeline.

Neither library is imported as a dependency. AXray is a clean-room implementation inspired by their ideas.

## Installation

```bash
# Clone and build
git clone https://github.com/deamonseed1973/axray.git
cd axray
swift build -c release

# Copy binary to PATH
cp .build/release/AXray /usr/local/bin/axray
```

Requires macOS 13+ and Xcode/Swift toolchain.

## Usage

### Inspect — Dump the augmented accessibility tree

```bash
# Basic AX tree dump
axray inspect Safari

# With Vision analysis on elements lacking AX text
axray inspect Safari --vision

# Deeper traversal, JSON output
axray inspect "com.apple.Safari" --depth 6 --vision --json
```

### Find — Search for elements by text

```bash
# Search AX text only
axray find Finder "Downloads"

# Also search Vision-detected text
axray find Safari "Sign In" --vision
```

### Audit — Flag accessibility issues

```bash
# Find elements where Vision sees text but AX doesn't
axray audit Safari

# JSON output for CI integration
axray audit "com.apple.Safari" --json
```

The audit command reports two types of issues:

- **Accessibility Gap** — Vision detects text in an element that has no AX label, title, or value. This element is invisible to screen readers and automation tools.
- **Label Mismatch** — The AX label doesn't match what's visually displayed. This can confuse users who rely on both visual and assistive interfaces.

## Permissions

AXray requires two macOS permissions at runtime:

1. **Accessibility** — System Settings > Privacy & Security > Accessibility. Required to read the AX tree of other applications.
2. **Screen Recording** — System Settings > Privacy & Security > Screen Recording. Required to capture screenshots of UI elements for Vision analysis.

Grant these to your terminal app (Terminal.app, iTerm2, etc.) or to the `axray` binary directly.

## Architecture

```
Sources/AXray/
├── AXrayCommand.swift          — Entry point, ArgumentParser root command
├── Core/
│   ├── AXElement.swift         — Lightweight model wrapping AXUIElement
│   ├── AXTreeWalker.swift      — Visitor-pattern tree traversal (from AXorcist)
│   ├── AppResolver.swift       — Find running apps by name or bundle ID
│   └── ScreenCapture.swift     — Capture screen rect via CGWindowListCreateImage
├── Vision/
│   ├── VisionPipeline.swift    — Parallel Vision requests (from Viz)
│   └── AnalysisResult.swift    — VisionResult and AugmentedElement models
├── Commands/
│   ├── InspectCommand.swift    — axray inspect
│   ├── FindCommand.swift       — axray find
│   └── AuditCommand.swift      — axray audit
└── Output/
    ├── TreePrinter.swift       — Pretty-print augmented tree
    └── JSONOutput.swift        — JSON output formatting
```

## Why This Combination Is Interesting

The accessibility API and computer vision see the same UI from fundamentally different angles. AX provides *structure* — parent-child relationships, roles, semantic labels — but only what the developer chose to expose. Vision provides *perception* — it sees rendered text regardless of whether anyone tagged it — but has no concept of UI hierarchy.

By overlaying Vision results onto the AX tree, AXray reveals the space between intent and implementation: every button with a visible label but no AX description, every custom view rendering text that assistive technology cannot read.

This makes AXray useful for:
- **Accessibility auditing** — Find gaps before your users do
- **UI automation** — Drive apps that expose minimal AX data by finding elements through their visual content
- **Debugging** — Understand what the AX tree actually contains vs. what you think it contains

## License

MIT
