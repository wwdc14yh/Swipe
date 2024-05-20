//
//  ViewController.swift
//  SwipeExample
//
//  Created by y H on 2024/5/11.
//

import UIKit
import Swipe
import UIComponent
import UIComponentSwipe

class ViewController: UIViewController {
    let componentView = ComponentScrollView()

    var emailData = EmailData.mockDatas {
        didSet {
            reloadComponent()
        }
    }

    var component: any Component {
        VStack(spacing: 20) {
            layoutEffect
            swipeStyle
            emailSwipe
        }
        .inset(h: 20)
    }

    var layoutEffect: any Component {
        func configSwipe(_ component: any Component, layoutEffect: SwipeConfig.LayoutEffect) -> any Component {
            component
                .swipeActions(leftExampleSwipeActions() + rightExampleSwipeActions())
                .swipeConfig(SwipeConfig(
                    layoutEffect: layoutEffect,
                    clipsToBounds: false
                ))
        }
        return Group(title: "Swipe layout effect", footnote: "The style of how the action views are exposed during the swipe.") {
            Join {
                configSwipe(
                    Cell(title: "border", subtitle: "The visible action area is equally divide between all action views."),
                    layoutEffect: .border
                )
                configSwipe(
                    Cell(title: "drag", subtitle: "The visible action area is dragged, pinned to the any view, with each action view fully sized as it is exposed."),
                    layoutEffect: .drag
                )
                configSwipe(
                    Cell(title: "static", subtitle: "The visible action area sits behind the any view, pinned to the edge of the any scroll view, and is revealed as the any view is dragged aside."),
                    layoutEffect: .static
                )
            } separator: {
                Separator()
            }
        }
    }

    var swipeStyle: any Component {
        Group(title: "Swipe custom styles") {
            VStack(spacing: 10, alignItems: .stretch) {
                Cell(title: "Rounded corners 1")
                    .tappableView { [unowned self] in
                        guard let componentView = componentView.visibleView(id: "Rounded corners 1") as? ComponentView,
                              let swipeView = componentView.visibleView(id: "Rounded corners 1") as? SwipeView else { return }
                        swipeView.openSwipeAction(with: .right, transition: .animated(duration: 0.5, curve: .easeInOut))
                    }
                    .clipsToBounds(false)
                    .backgroundColor(.systemGroupedBackground)
                    .with(\.layer.cornerRadius, 15)
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions()
                        rightExampleSwipeActions()
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .static,
                        gap: 5,
                        cornerRadius: .custom(15),
                        clipsToBounds: false
                    ))
                    .inset(h: 10)
                    .view()
                    .clipsToBounds(true)
                    .id("Rounded corners 1")
                Cell(title: "Rounded corners 2")
                    .tappableView { [unowned self] in
                        guard let componentView = componentView.visibleView(id: "Rounded corners 2") as? ComponentView,
                              let swipeView = componentView.visibleView(id: "Rounded corners 2") as? SwipeView else { return }
                        swipeView.openSwipeAction(with: .left, transition: .animated(duration: 0.5, curve: .easeInOut))
                    }
                    .backgroundColor(.systemGroupedBackground)
                    .roundedCorner()
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions()
                        rightExampleSwipeActions()
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .static,
                        itemSpacing: 1,
                        gap: 5,
                        cornerRadius: .round,
                        cornerRadiusType: .overall,
                        clipsToBounds: false
                    ))
                    .inset(h: 10)
                    .view()
                    .clipsToBounds(true)
                    .id("Rounded corners 2")
                Cell(title: "Rounded corners 3")
                    .backgroundColor(.systemGroupedBackground)
                    .roundedCorner()
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions()
                        rightExampleSwipeActions()
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .drag,
                        itemSpacing: 5,
                        gap: 5,
                        cornerRadius: .round,
                        cornerRadiusType: .unit,
                        clipsToBounds: false
                    ))
                    .inset(h: 10)
                    .view()
                    .clipsToBounds(true)
                    .id("Rounded corners 3")
            }
            .inset(v: 10)
        }
    }

    var emailSwipe: any Component {
        Group(title: "Inbox") {
            Join {
                for (offset, value) in emailData.enumerated() {
                    EmailComponent(data: value)
                        .swipeActions {
                            
                            // MARK: Left
                            
                            SwipeActionComponent(identifier: "read", horizontalEdge: .left, backgroundColor: UIColor(red: 0.008, green: 0.475, blue: 0.996, alpha: 1.0)) {
                                VStack(justifyContent: .center, alignItems: .center) {
                                    Image(systemName: value.unread ? "envelope.open.fill" : "envelope.fill")
                                        .tintColor(.white)
                                    Text(value.unread ? "Read" : "Unread", font: .systemFont(ofSize: 16, weight: .medium))
                                        .textColor(.white)
                                }
                                .inset(h: 10)
                                .minSize(width: 74, height: 0)
                            } actionHandler: { [unowned self] completion, action, form in
                                handlerEmail(action, offset: offset, completion: completion, eventForm: form)
                            }
                            remindSwipeAction(with: value)

                            // MARK: Right

                            customSwipeAction(item: value)
                            SwipeActionComponent(identifier: "flag", horizontalEdge: .right, backgroundColor: UIColor(red: 0.996, green: 0.624, blue: 0.024, alpha: 1.0)) {
                                VStack(justifyContent: .center, alignItems: .center) {
                                    Image(systemName: "flag.fill")
                                        .tintColor(.white)
                                    Text("Flag", font: .systemFont(ofSize: 16, weight: .medium))
                                        .textColor(.white)
                                }
                                .inset(h: 10)
                                .minSize(width: 74, height: 0)
                            } actionHandler: { [unowned self] completion, action, form in
                                handlerEmail(action, offset: offset, completion: completion, eventForm: form)
                            }
                            if value.unread {
                                SwipeActionComponent(identifier: "archive", horizontalEdge: .right, backgroundColor: UIColor(red: 0.749, green: 0.349, blue: 0.945, alpha: 1.0)) {
                                    VStack(justifyContent: .center, alignItems: .center) {
                                        Image(systemName: "archivebox.fill")
                                            .tintColor(.white)
                                        Text("Archive", font: .systemFont(ofSize: 16, weight: .medium))
                                            .textColor(.white)
                                    }
                                    .inset(h: 10)
                                    .minSize(width: 74, height: 0)
                                } actionHandler: { [unowned self] completion, action, form in
                                    handlerEmail(action, offset: offset, completion: completion, eventForm: form)
                                }
                            } else {
                                SwipeActionComponent(identifier: "trash", horizontalEdge: .right, backgroundColor: UIColor(red: 0.996, green: 0.271, blue: 0.227, alpha: 1.0)) {
                                    VStack(justifyContent: .center, alignItems: .center) {
                                        Image(systemName: "trash.fill")
                                            .tintColor(.white)
                                        Text("Trash", font: .systemFont(ofSize: 16, weight: .medium))
                                            .textColor(.white)
                                    }
                                    .inset(h: 10)
                                    .minSize(width: 74, height: 0)
                                } alertBuild: {
                                    HStack(spacing: 5, justifyContent: .center, alignItems: .center) {
                                        Image(systemName: "trash.fill")
                                            .tintColor(.white)
                                        Text("Are you sure?", font: .systemFont(ofSize: 20, weight: .semibold))
                                            .textColor(.white)
                                    }
                                } actionHandler: { [unowned self] completion, action, form in
                                    handlerEmail(action, offset: offset, completion: completion, eventForm: form)
                                }
                            }
                        }
                        .swipeConfig(SwipeConfig(layoutEffect: .border))
                }
            } separator: {
                Separator()
                    .inset(left: 30)
            }
        }
    }

    override func loadView() {
        super.loadView()
        view.addSubview(componentView)
        componentView.backgroundColor = .systemGroupedBackground
        componentView.animator = TransformAnimator(cascade: true)
        reloadComponent()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        componentView.frame = view.bounds
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        reloadComponent()
    }

    func leftExampleSwipeActions() -> [any SwipeAction] {
        [
            SwipeActionComponent(
                horizontalEdge: .left,
                body: SwipeActionContent(image: UIImage(systemName: "square.and.arrow.up.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 255 / 255.0, green: 149 / 255.0, blue: 0 / 255.0, alpha: 1.0)
            ),
            SwipeActionComponent(
                horizontalEdge: .left,
                body: SwipeActionContent(image: UIImage(systemName: "paperplane.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: .systemGreen
            ),
            SwipeActionComponent(
                horizontalEdge: .left,
                body: SwipeActionContent(image: UIImage(systemName: "video.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 0 / 255.0, green: 122 / 255.0, blue: 255 / 255.0, alpha: 1.0)
            ),
        ]
    }

    func rightExampleSwipeActions() -> [any SwipeAction] {
        [
            SwipeActionComponent(
                horizontalEdge: .right,
                body: SwipeActionContent(image: UIImage(systemName: "bookmark.fill"), text: "Save", alignment: .ltr, tintColor: UIColor(red: 0, green: 0.353, blue: 0.851, alpha: 1.0)),
                backgroundColor: UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0)
            ),
            SwipeActionComponent(
                horizontalEdge: .right,
                body: SwipeActionContent(image: nil, text: "Delete", alignment: .ltr, tintColor: .white),
                expanded: SwipeActionContent(image: UIImage(systemName: "trash.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 0.80, green: 0, blue: 0.137, alpha: 1.0)
            ),
        ]
    }

    func customSwipeAction(item: EmailData) -> SwipeActionComponent {
        var completionAfterHandler: SwipeAction.CompletionAfterHandler?
        var primaryMenuSwipeAction = SwipeActionComponent(
            identifier: UUID().uuidString,
            horizontalEdge: .right,
            backgroundColor: UIColor(red: 0.553, green: 0.553, blue: 0.553, alpha: 1.0),
            alertBuild: {
                SwipeActionContent(image: UIImage(systemName: "info.circle.fill"), text: "This is custom action", alignment: .ltr, tintColor: .white)
            },
            actionHandler: { completion, _, form in
                if form == .alert {
                    completion(.close)
                } else {
                    completionAfterHandler = completion
                }
            }
        )
        primaryMenuSwipeAction.body = SwipeActionContent(image: UIImage(systemName: "ellipsis.circle.fill"), text: "More", alignment: .ttb, tintColor: .white)
            .primaryMenu {
                let actionHandler: UIActionHandler = { action in
                    if action.title == "hold" {
                        completionAfterHandler?(.hold)
                    } else if action.title == "close" {
                        completionAfterHandler?(.close)
                    } else if action.title == "expanded" {
                        completionAfterHandler?(.expanded(completed: nil))
                    } else if action.title == "alert" {
                        completionAfterHandler?(.alert)
                    }
                }
                return UIMenu(title: "Custom after handle (\(item.from))", children: [
                    UIAction(title: "hold", handler: actionHandler),
                    UIAction(title: "close", handler: actionHandler),
                    UIAction(title: "expanded", handler: actionHandler),
                    UIAction(title: "alert", handler: actionHandler),
                ])
            }
        return primaryMenuSwipeAction
    }

    func remindSwipeAction(with emailData: EmailData) -> SwipeActionComponent {
        var primaryMenuSwipeAction = SwipeActionComponent(
            horizontalEdge: .left,
            backgroundColor: UIColor(red: 0.341, green: 0.333, blue: 0.835, alpha: 1.0),
            actionHandler: { completion, _, form in
                if form == .alert {
                    completion(.expanded(completed: nil))
                }
            }
        )
        let primaryMenuComponent = VStack(alignItems: .center) {
            Image(systemName: "clock.fill")
                .tintColor(.white)
            Text("Remind", font: .systemFont(ofSize: 16, weight: .medium))
                .textColor(.white)
        }
        .inset(h: 10)
        .minSize(width: 74)
        .primaryMenu {
            let actionHandler: UIActionHandler = { [unowned self] action in
                guard let swipeView = componentView.visibleView(id: emailData.id) as? SwipeView else { return }
                if action.title == "Remind me later..." {
                    swipeView.manualHandlerAfter(afterHandler: .alert, action: primaryMenuSwipeAction)
                } else {
                    swipeView.manualHandlerAfter(afterHandler: .close, action: primaryMenuSwipeAction)
                }
            }
            return UIMenu(title: "Remind me", children: [
                UIAction(title: "Remind me in 1 hour", handler: actionHandler),
                UIAction(title: "Remind me tomorrow", handler: actionHandler),
                UIAction(title: "Remind me later...", handler: actionHandler),
            ])
        }
        let alertComponent = {
            Text("This is custom action", font: .systemFont(ofSize: 18, weight: .medium))
                .textColor(.white)
                .adjustsFontSizeToFitWidth(true)
                .textAlignment(.center)
                .inset(5)
                .flex()
        }
        primaryMenuSwipeAction.alert = alertComponent()
        primaryMenuSwipeAction.body = primaryMenuComponent
        return primaryMenuSwipeAction
    }

    func handlerEmail(_ action: any SwipeAction, offset: Int, completion: @escaping SwipeAction.CompletionAfterHandler, eventForm: SwipeActionEventFrom) {
        if action.identifier == "read" {
            var data = emailData[offset]
            data.unread.toggle()
            emailData[offset] = data
            completion(.close)
        } else if action.identifier == "trash" {
            if eventForm == .expanded || eventForm == .alert {
                let removed: () -> Void = { [unowned self] in
                    emailData.remove(at: offset)
                }
                completion(.expanded(completed: removed))
            } else {
                completion(.alert)
            }
        } else {
            completion(.close)
        }
    }

    func reloadComponent() {
        componentView.component = component
    }
}
