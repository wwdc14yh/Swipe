//  Created by y H on 2024/5/11.

import UIKit
import Swipe
@preconcurrency import UIComponent

public struct SwipeActionComponent: SwipeAction {
    public static let defaultConfigHighlightView: ConfigHighlightView = { highlightView, isHighlighted in
        Task { @MainActor in
            highlightView.backgroundColor = .black.withAlphaComponent(isHighlighted ? 0.3 : 0)
        }
    }

    public typealias ConfigHighlightView = @MainActor @Sendable (_ highlightView: UIView, _ isHighlighted: Bool) -> Void
    public typealias ActionHandler = @Sendable (_ completion: @escaping @Sendable CompletionAfterHandler, _ action: any SwipeAction, _ from: SwipeActionEventFrom) -> Void
    public typealias ComponentProvider = () -> any Component

    public let identifier: String
    public let horizontalEdge: SwipeHorizontalEdge
    public var alert: (any Component)?
    public var background: (any Component)?
    public var body: (any Component)?
    public var expanded: (any Component)?

    public let actionHandler: SwipeActionComponent.ActionHandler
    public let configHighlightView: ConfigHighlightView
    
    public var isEnableFadeTransitionAddedExpandedView: Bool {
        expanded != nil
    }

    public init(
        horizontalEdge: SwipeHorizontalEdge,
        backgroundColor: UIColor,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.init(
            identifier: UUID().uuidString,
            horizontalEdge: horizontalEdge,
            backgroundColor: backgroundColor,
            body: nil,
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    @MainActor
    @preconcurrency
    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        backgroundColor: UIColor,
        bodyBuild: SwipeActionComponent.ComponentProvider? = nil,
        alertBuild: SwipeActionComponent.ComponentProvider? = nil,
        expandedBuild: SwipeActionComponent.ComponentProvider? = nil,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            bodyBuild: bodyBuild,
            backgroundBuild: {
                Space().backgroundColor(backgroundColor)
            },
            alertBuild: alertBuild,
            expandedBuild: expandedBuild,
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        bodyBuild: SwipeActionComponent.ComponentProvider? = nil,
        backgroundBuild: SwipeActionComponent.ComponentProvider? = nil,
        alertBuild: SwipeActionComponent.ComponentProvider? = nil,
        expandedBuild: SwipeActionComponent.ComponentProvider? = nil,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            body: bodyBuild?(),
            background: backgroundBuild?(),
            alert: alertBuild?(),
            expanded: expandedBuild?(),
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }
    
    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        backgroundColor: UIColor,
        body: (any Component)?,
        alert: (any Component)? = nil,
        expanded: (any Component)? = nil,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        var bodyProvider: ComponentProvider? {
            guard let body else { return nil }
            return { body }
        }
        var alertProvider: ComponentProvider? {
            guard let alert else { return nil }
            return { alert }
        }
        var expandedProvider: ComponentProvider? {
            guard let expanded else { return nil }
            return { expanded }
        }
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            backgroundColor: backgroundColor,
            bodyBuild: bodyProvider,
            alertBuild: alertProvider,
            expandedBuild: expandedProvider,
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        body: (any Component)? = nil,
        background: (any Component)? = nil,
        alert: (any Component)? = nil,
        expanded: (any Component)? = nil,
        configHighlightView: @escaping ConfigHighlightView = SwipeActionComponent.defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.identifier = identifier
        self.horizontalEdge = horizontalEdge
        self.alert = alert
        self.background = background
        self.body = body
        self.expanded = expanded
        self.configHighlightView = configHighlightView
        self.actionHandler = actionHandler
    }
    
    public func makeBackgroundView() -> UIView {
        let componentView = ComponentView()
        componentView.component = ZStack(verticalAlignment: .stretch, horizontalAlignment: .stretch) { background ?? Space() }
            .fill()
        return componentView
    }

    public func makeCotnentView() -> UIView {
        let contentView = ComponentView()
        contentView.component = wrapLayout(body: body, justifyContent: horizontalEdge.isLeft ? .end : .start)
        return contentView
    }

    public func makeExpandedView() -> UIView? {
        guard let expanded else {
            return nil
        }
        let componentView = ComponentView()
        componentView.component = wrapLayout(body: expanded, justifyContent: horizontalEdge == .left ? .end : .start)
        return componentView
    }

    public func makeAlertView() -> UIView {
        guard let alert else { fatalError("Implement alert closure") }
        let componentView = ComponentView()
        componentView.component = wrapLayout(body: alert, justifyContent: .center)
        return componentView
    }

    public func handlerAction(completion: @escaping CompletionAfterHandler, eventFrom: SwipeActionEventFrom) {
        actionHandler(completion, self, eventFrom)
    }

    public func configHighlightView(with highlightView: UIView, isHighlighted: Bool) {
        configHighlightView(highlightView, isHighlighted)
    }

    func wrapLayout(body: (any Component)?, justifyContent: MainAxisAlignment, alignItems: CrossAxisAlignment = .center) -> WrapLayout {
        WrapLayout(justifyContent: justifyContent, alignItems: alignItems) { body }
    }

    struct WrapLayout: ComponentBuilder {
        let justifyContent: MainAxisAlignment
        let alignItems: CrossAxisAlignment
        let components: [any Component]
        init(justifyContent: MainAxisAlignment, alignItems: CrossAxisAlignment, @ComponentArrayBuilder _ components: () -> [any Component]) {
            self.justifyContent = justifyContent
            self.alignItems = alignItems
            self.components = components()
        }

        func build() -> some Component {
            HStack(justifyContent: justifyContent, alignItems: alignItems) {
                components
            }
            .fill()
        }
    }
}
