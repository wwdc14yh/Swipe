//  Created by y H on 2024/4/7.

import UIKit

public typealias SwipeActionHandler = (_ action: any SwipeAction) -> Void

public enum SwipeHorizontalEdge {
    case left, right
    public var isLeft: Bool { self == .left }
}

public enum SwipeActionEventFrom {
    case tap
    case expanded
    case alert
}

public enum SwipeActionAfterHandler {
    public typealias TransitionCompleted = () -> Void
    case hold
    case close
    case swipeFull(TransitionCompleted? = nil)
    case alert
}

public protocol SwipeAction {
    typealias CompletionAfterHandler = (SwipeActionAfterHandler) -> Void
    associatedtype View: UIView
    var identifier: String { get }
    var horizontalEdge: SwipeHorizontalEdge { get }
    var view: View { get }
    var isEnableFadeTransitionAddedExpandedView: Bool { get }
    func configHighlightView(with highlightView: UIView, isHighlighted: Bool)
    func makeExpandedView() -> UIView?
    func makeAlertView() -> UIView
    func handlerAction(completion: @escaping CompletionAfterHandler, eventFrom: SwipeActionEventFrom)
    func willShow()
}

public extension SwipeAction {
    var swipeView: SwipeView<UIView>? {
        sequence(first: view.superview, next: { $0?.superview }).compactMap { $0 as? SwipeView }.first
    }
    
    var isEnableFadeTransitionAddedExpandedView: Bool { true }
    
    func configHighlightView(with highlightView: UIView, isHighlighted: Bool) {}
    
    func makeExpandedView() -> UIView? {
        return nil
    }
    
    func makeAlertView() -> UIView {
        fatalError()
    }
    
    func willShow() {}
    
    func manualHandlerAfter(afterHandler: SwipeActionAfterHandler) {
        guard let swipeView else { return }
        swipeView.afterHandler(with: afterHandler, action: self)
    }
    
    internal func isSame(_ other: any SwipeAction) -> Bool {
        identifier == other.identifier && horizontalEdge == other.horizontalEdge
    }
    
    internal var wrapView: SwipeActionWrapView? {
        sequence(first: view.superview, next: { $0?.superview }).compactMap { $0 as? SwipeActionWrapView }.first
    }
}

public extension SwipeAction {
    static func == (lhs: any SwipeAction, rhs: any SwipeAction) -> Bool {
        lhs.identifier == rhs.identifier
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

