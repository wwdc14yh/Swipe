//  Created by y H on 2024/5/11.

import UIKit
import Swipe
import UIComponent

public struct SwipeActionComponent: SwipeAction {
    public static let blankActionHandler: ActionHandler = { _, _, _ in }
    public static let defaultConfigHighlightView: ConfigHighlightView = { highlightView, isHighlighted in
        highlightView.backgroundColor = .black.withAlphaComponent(isHighlighted ? 0.3 : 0)
    }

    public typealias ConfigHighlightView = (_ highlightView: UIView, _ isHighlighted: Bool) -> Void
    public typealias ActionHandler = (_ completion: @escaping CompletionAfterHandler, _ action: any SwipeAction, _ form: SwipeActionEventFrom) -> Void
    public typealias ComponentProvider = () -> any Component

    public let identifier: String
    public let horizontalEdge: SwipeHorizontalEdge
    public var alert: (any Component)?
    public var background: (any Component)?
    public var body: (any Component)?

    public let actionHandler: SwipeActionComponent.ActionHandler
    public let isEnableFadeTransitionAddedExpandedView = false
    public let configHighlightView: ConfigHighlightView

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

    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        backgroundColor: UIColor,
        body: (any Component)?,
        alert: (any Component)? = nil,
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
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            backgroundColor: backgroundColor,
            bodyBuild: bodyProvider,
            alertBuild: alertProvider,
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    /// Builder and backgroundColor func
    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        backgroundColor: UIColor,
        bodyBuild: SwipeActionComponent.ComponentProvider? = nil,
        alertBuild: SwipeActionComponent.ComponentProvider? = nil,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            bodyBuild: bodyBuild,
            backgroundBuild: { Space().backgroundColor(backgroundColor) },
            alertBuild: alertBuild,
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    /// Builder func
    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        bodyBuild: SwipeActionComponent.ComponentProvider? = nil,
        backgroundBuild: SwipeActionComponent.ComponentProvider? = nil,
        alertBuild: SwipeActionComponent.ComponentProvider? = nil,
        configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.init(
            identifier: identifier,
            horizontalEdge: horizontalEdge,
            body: bodyBuild?(),
            background: backgroundBuild?(),
            alert: alertBuild?(),
            configHighlightView: configHighlightView,
            actionHandler: actionHandler
        )
    }

    public init(
        identifier: String,
        horizontalEdge: SwipeHorizontalEdge,
        body: (any Component)?,
        background: (any Component)?,
        alert: (any Component)?,
        configHighlightView: @escaping ConfigHighlightView,
        actionHandler: @escaping SwipeActionComponent.ActionHandler
    ) {
        self.identifier = identifier
        self.horizontalEdge = horizontalEdge
        self.alert = alert
        self.background = background
        self.body = body
        self.configHighlightView = configHighlightView
        self.actionHandler = actionHandler
    }

    public func makeCotnentView() -> UIView {
        let contentView = ComponentView()
        contentView.component = wrapLayout(body: body, justifyContent: horizontalEdge.isLeft ? .end : .start)
        return contentView
    }

    public func makeExpandedView() -> UIView? {
        let componentView = ComponentView()
        componentView.component = wrapLayout(body: body, justifyContent: horizontalEdge == .left ? .end : .start)
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
        WrapLayout(justifyContent: justifyContent, alignItems: alignItems, background: background ?? Space()) { body }
    }

    struct WrapLayout: ComponentBuilder {
        let justifyContent: MainAxisAlignment
        let alignItems: CrossAxisAlignment
        let components: [any Component]
        let background: any Component
        init(justifyContent: MainAxisAlignment, alignItems: CrossAxisAlignment, background: any Component, @ComponentArrayBuilder _ components: () -> [any Component]) {
            self.justifyContent = justifyContent
            self.alignItems = alignItems
            self.components = components()
            self.background = background
        }

        func build() -> some Component {
            HStack(justifyContent: justifyContent, alignItems: alignItems) {
                components
            }
            .fill()
            .background {
                background
            }
        }
    }
}
