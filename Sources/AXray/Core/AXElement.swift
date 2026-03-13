import ApplicationServices
import Foundation

/// Lightweight wrapper around AXUIElement providing typed access to common attributes.
struct AXElement {
    let element: AXUIElement

    var role: String? { attribute(kAXRoleAttribute) }
    var title: String? { attribute(kAXTitleAttribute) }
    var value: String? { attribute(kAXValueAttribute) }
    var label: String? { attribute(kAXDescriptionAttribute) }
    var identifier: String? { attribute(kAXIdentifierAttribute) }
    var roleDescription: String? { attribute(kAXRoleDescriptionAttribute) }
    var help: String? { attribute(kAXHelpAttribute) }
    var placeholderValue: String? { attribute("AXPlaceholderValue") }

    /// Screen frame of this element (in global screen coordinates).
    var frame: CGRect? {
        guard let posVal: AXValue = axValue(kAXPositionAttribute),
              let sizeVal: AXValue = axValue(kAXSizeAttribute) else { return nil }
        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posVal, .cgPoint, &position)
        AXValueGetValue(sizeVal, .cgSize, &size)
        return CGRect(origin: position, size: size)
    }

    /// Direct children of this element.
    var children: [AXElement] {
        guard let childrenRef: CFArray = cfValue(kAXChildrenAttribute) else { return [] }
        let count = CFArrayGetCount(childrenRef)
        var result: [AXElement] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            guard let rawPtr = CFArrayGetValueAtIndex(childrenRef, i) else { continue }
            // AXUIElement is a CFTypeRef; check type ID before casting
            let axTypeID = AXUIElementGetTypeID()
            let valueTypeID = CFGetTypeID(Unmanaged<CFTypeRef>.fromOpaque(rawPtr).takeUnretainedValue())
            guard valueTypeID == axTypeID else { continue }
            let child = Unmanaged<AXUIElement>.fromOpaque(rawPtr).takeUnretainedValue()
            result.append(AXElement(element: child))
        }
        return result
    }

    /// Concatenation of all AX-provided text attributes.
    var axText: String {
        [title, value, label, identifier, placeholderValue, help]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    /// Whether the AX system considers this element ignored.
    var isIgnored: Bool {
        var ref: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, "AXIsIgnored" as CFString, &ref)
        if result == .success, let v = ref as? Bool { return v }
        return false
    }

    /// Stable hash for cycle detection.
    var cfHash: CFHashCode {
        CFHash(element)
    }

    // MARK: - Private helpers

    private func attribute<T>(_ attr: String) -> T? {
        var ref: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attr as CFString, &ref)
        guard result == .success else { return nil }
        return ref as? T
    }

    private func axValue<T: AnyObject>(_ attr: String) -> T? {
        attribute(attr)
    }

    private func cfValue<T: AnyObject>(_ attr: String) -> T? {
        attribute(attr)
    }
}
