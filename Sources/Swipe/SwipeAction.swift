//  Created by y H on 2024/4/7.

import UIKit

public typealias SwipeActionHandler = (_ action: any SwipeAction) -> Void

public enum SwipeHorizontalEdge: Sendable {
    case left, right
    public var isLeft: Bool { self == .left }
}

public enum SwipeActionEventFrom: Sendable {
    case tap
    case expanded
    case alert
}

public enum SwipeActionAfterHandler: Sendable {
    public typealias TransitionCompleted = @Sendable () -> Void
    case hold
    case close
    case expanded(completed: TransitionCompleted? = nil)
    case alert
}

@MainActor
public protocol SwipeAction: Sendable {
    typealias CompletionAfterHandler = @Sendable (SwipeActionAfterHandler) -> Void
    associatedtype ContentView: UIView
    var identifier: String { get }
    var horizontalEdge: SwipeHorizontalEdge { get }
    var isEnableFadeTransitionAddedExpandedView: Bool { get }
    
    func configHighlightView(with highlightView: UIView, isHighlighted: Bool)
    
    func update(contentView: ContentView)
    
    func handlerAction(completion: @escaping CompletionAfterHandler, eventFrom: SwipeActionEventFrom)
    
    func willShow()

    func makeCotnentView() -> ContentView
    
    func makeBackgroundView() -> UIView
    
    func makeExpandedView() -> UIView?
    
    func makeAlertView() -> UIView
}

public extension SwipeAction {
    var isEnableFadeTransitionAddedExpandedView: Bool { true }

    func configHighlightView(with _: UIView, isHighlighted _: Bool) {}

    func update(contentView: ContentView) {}
    
    func makeExpandedView() -> UIView? {
        return nil
    }

    func makeAlertView() -> UIView {
        fatalError()
    }

    func willShow() {}
    
    internal func _update(contentView: UIView) {
        guard let contentView = contentView as? ContentView else { return }
        update(contentView: contentView)
    }

    internal func isSame(_ other: (any SwipeAction)?) -> Bool {
        guard let other else { return false }
        return identifier == other.identifier && horizontalEdge == other.horizontalEdge
    }
}

@resultBuilder
public enum SwipeActionBuilder {
    public static func buildExpression(_ expression: any SwipeAction) -> [any SwipeAction] {
        [expression]
    }

    public static func buildExpression(_ expression: (any SwipeAction)?) -> [any SwipeAction] {
        [expression].compactMap { $0 }
    }

    public static func buildExpression(_ expression: [any SwipeAction]) -> [any SwipeAction] {
        expression
    }

    public static func buildBlock(_ segments: [any SwipeAction]...) -> [any SwipeAction] {
        segments.flatMap { $0 }
    }

    public static func buildIf(_ segments: [any SwipeAction]?...) -> [any SwipeAction] {
        segments.flatMap { $0 ?? [] }
    }

    public static func buildEither(first: [any SwipeAction]) -> [any SwipeAction] {
        first
    }

    public static func buildEither(second: [any SwipeAction]) -> [any SwipeAction] {
        second
    }

    public static func buildArray(_ components: [[any SwipeAction]]) -> [any SwipeAction] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [any SwipeAction]) -> [any SwipeAction] {
        component
    }
}
