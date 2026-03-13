import Foundation

/// Controls traversal after visiting each element.
enum VisitorResult {
    case `continue`
    case skipChildren
    case stop
}

/// Visitor protocol for AX tree traversal (inspired by AXorcist).
protocol ElementVisitor {
    mutating func visit(_ element: AXElement, depth: Int) -> VisitorResult
}

/// Walk the accessibility tree from a root element using the visitor pattern.
/// Includes cycle detection via CFHash to avoid infinite loops.
func walkTree(
    from element: AXElement,
    visitor: inout some ElementVisitor,
    maxDepth: Int = 6,
    currentDepth: Int = 0,
    visited: inout Set<CFHashCode>
) {
    let hash = element.cfHash
    guard !visited.contains(hash) else { return }
    visited.insert(hash)

    guard currentDepth <= maxDepth else { return }

    let result = visitor.visit(element, depth: currentDepth)
    switch result {
    case .stop:
        return
    case .skipChildren:
        break
    case .continue:
        for child in element.children {
            walkTree(
                from: child,
                visitor: &visitor,
                maxDepth: maxDepth,
                currentDepth: currentDepth + 1,
                visited: &visited
            )
        }
    }
}

/// Convenience overload that creates the visited set automatically.
func walkTree(
    from element: AXElement,
    visitor: inout some ElementVisitor,
    maxDepth: Int = 6
) {
    var visited = Set<CFHashCode>()
    walkTree(from: element, visitor: &visitor, maxDepth: maxDepth, currentDepth: 0, visited: &visited)
}
