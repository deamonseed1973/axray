import CoreGraphics
import AppKit
import Foundation

/// Captures the screen region corresponding to an AXElement's frame.
enum ScreenCapture {
    /// Capture the screen content at the given element's frame.
    /// Returns nil if the element has no frame or the frame is too small.
    static func captureElement(_ element: AXElement) -> CGImage? {
        guard let frame = element.frame,
              frame.width > 2, frame.height > 2 else { return nil }

        // Capture the specific screen rect directly
        let image = CGWindowListCreateImage(
            frame,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
        return image
    }

    /// Capture a specific screen rect.
    static func captureRect(_ rect: CGRect) -> CGImage? {
        guard rect.width > 2, rect.height > 2 else { return nil }
        return CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }
}
