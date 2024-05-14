//  Created by y H on 2024/4/7.

import Swipe
import Foundation
import UIComponent

public struct SwipeComponent: Component {
    public let component: any Component

    @Environment(\.swipeConfig)
    public var config: SwipeConfig

    public var actions: [any SwipeAction]

    public init(component: any Component, @SwipeActionBuilder _ actionsBuilder: () -> [any SwipeAction]) {
        self.component = component
        actions = actionsBuilder()
    }

    public func layout(_ constraint: Constraint) -> SwipeRenderNode {
        let renderNode = component.layout(constraint)
        return SwipeRenderNode(
            size: renderNode.size.bound(to: constraint),
            component: component,
            content: renderNode,
            actions: actions,
            config: config
        )
    }
}

public struct SwipeRenderNode: RenderNode {
    /// The size of the render node.
    public let size: CGSize

    /// The component that is being rendered by this node.
    public let component: any Component

    /// The rendered content of the component.
    public let content: any RenderNode

    public let actions: [any SwipeAction]

    public let config: SwipeConfig

    public var id: String? {
        content.id
    }

    public var animator: Animator? {
        content.animator
    }

    public var reuseStrategy: ReuseStrategy {
        content.reuseStrategy
    }

    public func updateView(_ view: SwipeView) {
        view.config = config
        view.actions = actions
        (view.contentView as! ComponentView).engine.reloadWithExisting(component: component, renderNode: content)
    }

    public func makeView() -> SwipeView {
        let componentView = ComponentView()
        componentView.engine.reloadWithExisting(component: component, renderNode: content)
        return .init(contentView: componentView)
    }
}

// MARK: - Environment

public struct SwipeConfigEnvironmentKey: EnvironmentKey {
    public static var defaultValue: SwipeConfig {
        get {
            SwipeConfig.default
        }
        set {
            SwipeConfig.default = newValue
        }
    }
}

public extension EnvironmentValues {
    /// The `SwipeConfig` instance for the current environment.
    var swipeConfig: SwipeConfig {
        get { self[SwipeConfigEnvironmentKey.self] }
        set { self[SwipeConfigEnvironmentKey.self] = newValue }
    }
}

/// An extension to allow `Component` to modify its environment's `SwipeConfig`.
public extension Component {
    /// Modifies the current `SwipeConfig` of the component's environment.
    ///
    /// - Parameter SwipeConfig: The `SwipeConfig` to set in the environment.
    /// - Returns: An `EnvironmentComponent` configured with the new `PrimaryMenuConfig`.
    func swipeConfig(_ swipeConfig: SwipeConfig) -> EnvironmentComponent<SwipeConfig, Self> {
        environment(\.swipeConfig, value: swipeConfig)
    }
}

public extension Component {
    func swipeAction(@SwipeActionBuilder _ actionsBuilder: () -> [any SwipeAction]) -> SwipeComponent {
        SwipeComponent(component: self, actionsBuilder)
    }

    func swipeAction(_ actions: [any SwipeAction]) -> SwipeComponent {
        SwipeComponent(component: self) { actions }
    }
}
