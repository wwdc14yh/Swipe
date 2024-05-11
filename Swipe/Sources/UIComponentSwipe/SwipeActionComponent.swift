//  Created by y H on 2024/5/11.

import UIKit
import Swipe
import UIComponent

public struct SwipeActionComponent: SwipeAction {
    public static let blankActionHandler: ActionHandler = {_, _, _ in}
    public static let defaultConfigHighlightView: ConfigHighlightView = { highlightView, isHighlighted in
        highlightView.backgroundColor = .black.withAlphaComponent(isHighlighted ? 0.3 : 0)
    }
    public typealias ConfigHighlightView = (_ highlightView: UIView, _ isHighlighted: Bool) -> Void
    public typealias ActionHandler = (_ completion: @escaping CompletionAfterHandler, _ action: any SwipeAction, _ form: SwipeActionEventFrom) -> Void
    public typealias ComponentWithParameterProvider = () -> any Component
    public typealias ComponentProvider = () -> any Component
    public let identifier: String
    public let horizontalEdge: SwipeHorizontalEdge
    public let view: ComponentView
    public let alert: (any Component)?
    public let background: any Component
    public var component: (any Component)? {
        didSet { view.component = wrapLayout(body: component, justifyContent: horizontalEdge.isLeft ? .end : .start) }
    }
    public let actionHandler: SwipeActionComponent.ActionHandler
    public let isEnableFadeTransitionAddedExpandedView: Bool = false
    public let configHighlightView: ConfigHighlightView
    
    public static func custom(identifier: String = UUID().uuidString,
                              horizontalEdge: SwipeHorizontalEdge,
                              backgroundColor: UIColor,
                              body: SwipeActionComponent.ComponentProvider? = nil,
                              alert: SwipeActionComponent.ComponentProvider? = nil,
                              configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
                              actionHandler: @escaping SwipeActionComponent.ActionHandler = blankActionHandler) -> Self {
        self.init(identifier: identifier,
                  horizontalEdge: horizontalEdge,
                  backgroundColor: backgroundColor,
                  body: body,
                  alert: alert,
                  configHighlightView: configHighlightView,
                  actionHandler: actionHandler)
    }
    
    public init(identifier: String = UUID().uuidString,
                horizontalEdge: SwipeHorizontalEdge,
                backgroundColor: UIColor,
                body: SwipeActionComponent.ComponentProvider?,
                alert: SwipeActionComponent.ComponentProvider? = nil,
                configHighlightView: @escaping ConfigHighlightView = defaultConfigHighlightView,
                actionHandler: @escaping SwipeActionComponent.ActionHandler) {
        self.init(identifier: identifier,
                  horizontalEdge: horizontalEdge,
                  component: body,
                  background: { Space().backgroundColor(backgroundColor) },
                  alert: alert,
                  configHighlightView: configHighlightView,
                  actionHandler: actionHandler)
    }

    public init(identifier: String,
         horizontalEdge: SwipeHorizontalEdge,
         component: SwipeActionComponent.ComponentProvider?,
         background: SwipeActionComponent.ComponentProvider?,
         alert: ComponentProvider?,
                configHighlightView: @escaping ConfigHighlightView,
         actionHandler: @escaping SwipeActionComponent.ActionHandler) {
        self.identifier = identifier
        self.horizontalEdge = horizontalEdge
        let component = component?()
        let background = background?() ?? Space()
        self.alert = alert?()
        self.background = background
        self.component = component
        self.configHighlightView = configHighlightView
        self.actionHandler = actionHandler
        self.view = ComponentView()
        self.view.component = wrapLayout(body: component, justifyContent: horizontalEdge.isLeft ? .end : .start)
    }

    public func makeExpandedView() -> UIView? {
        let componentView = ComponentView()
        componentView.component = wrapLayout(body: component, justifyContent: horizontalEdge == .left ? .end : .start)
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
        self.configHighlightView(highlightView, isHighlighted)
    }

    func wrapLayout(body: (any Component)?, justifyContent: MainAxisAlignment, alignItems: CrossAxisAlignment = .center) -> WrapLayout {
        WrapLayout(justifyContent: justifyContent, alignItems: alignItems,  background: background) { body }
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
