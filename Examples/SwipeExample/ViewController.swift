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
            swipeStyle
            emailSwipe
        }
        .inset(view.safeAreaInsets)
        .inset(h: 20)
    }

    var swipeStyle: any Component {
        Group(title: "Swipe custom styles") {
            VStack(spacing: 10, alignItems: .stretch) {
                Cell(title: "Rounded corners 1")
                    .backgroundColor(.systemGroupedBackground)
                    .with(\.layer.cornerRadius, 15)
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions(0)
                        rightExampleSwipeActions(0)
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .static,
                        itemSpacing: 0,
                        gap: 5,
                        cornerRadius: 15,
                        clipsToBounds: false
                    ))
                Cell(title: "Rounded corners 2")
                    .backgroundColor(.systemGroupedBackground)
                    .with(\.layer.cornerRadius, 15)
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions()
                        rightExampleSwipeActions()
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .reveal,
                        itemSpacing: 5,
                        gap: 5,
                        cornerRadius: 15,
                        clipsToBounds: false
                    ))
                Cell(title: "Rounded corners 3")
                    .backgroundColor(.systemGroupedBackground)
                    .with(\.layer.cornerRadius, 15)
                    .with(\.layer.cornerCurve, .continuous)
                    .swipeActions {
                        leftExampleSwipeActions(99)
                        rightExampleSwipeActions(999)
                    }
                    .swipeConfig(SwipeConfig(
                        layoutEffect: .drag,
                        itemSpacing: 5,
                        gap: 5,
                        cornerRadius: 15,
                        clipsToBounds: false
                    ))
            }
            .inset(10)
        }
    }

    var emailSwipe: any Component {
        Group(title: "收件箱") {
            Join {
                for (offset, value) in emailData.enumerated() {
                    EmailComponent(data: value)
                        .swipeActions {
                            remindSwipeAction()
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

                            // MARK: Right

                            SwipeActionComponent(identifier: "more", horizontalEdge: .right, backgroundColor: UIColor(red: 0.553, green: 0.553, blue: 0.553, alpha: 1.0)) {
                                VStack(justifyContent: .center, alignItems: .center) {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .tintColor(.white)
                                    Text("More", font: .systemFont(ofSize: 16, weight: .medium))
                                        .textColor(.white)
                                }
                                .inset(h: 10)
                                .minSize(width: 74, height: 0)
                            } actionHandler: { [unowned self] completion, action, form in
                                handlerEmail(action, offset: offset, completion: completion, eventForm: form)
                            }
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
                        .swipeConfig(SwipeConfig(layoutEffect: .reveal))
                }
            } separator: {
                Separator()
                    .inset(left: 30)
            }
            .components
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

    func leftExampleSwipeActions(_ cornerRadius: CGFloat = 15) -> [any SwipeAction] {
        [
            SwipeActionComponent.rounded(
                horizontalEdge: .left,
                body: SwipeActionContent(image: UIImage(systemName: "square.and.arrow.up.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 255/255.0, green: 149/255.0, blue: 0/255.0, alpha: 1.0),
                cornerRadius: cornerRadius
            ),
            SwipeActionComponent.rounded(
                horizontalEdge: .left,
                body: SwipeActionContent(image: UIImage(systemName: "video.fill"), text: "", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0),
                cornerRadius: cornerRadius
            ),
        ]
    }

    func rightExampleSwipeActions(_ cornerRadius: CGFloat = 15) -> [any SwipeAction] {
        [
            SwipeActionComponent.rounded(
                horizontalEdge: .right,
                body: SwipeActionContent(image: UIImage(systemName: "bookmark.fill"), text: "Save", alignment: .ltr, tintColor: UIColor(red: 0, green: 0.353, blue: 0.851, alpha: 1.0)),
                backgroundColor: UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0),
                cornerRadius: cornerRadius
            ),
            SwipeActionComponent.rounded(
                horizontalEdge: .right,
                body: SwipeActionContent(image: nil, text: "Delete", alignment: .ltr, tintColor: .white),
                backgroundColor: UIColor(red: 0.80, green: 0, blue: 0.137, alpha: 1.0),
                cornerRadius: cornerRadius
            ),
        ]
    }

    func remindSwipeAction() -> SwipeActionComponent {
        var primaryMenuSwipeAction = SwipeActionComponent.custom(
            horizontalEdge: .left,
            backgroundColor: UIColor(red: 0.341, green: 0.333, blue: 0.835, alpha: 1.0),
            alertBuild: {
                Text("This is custom action", font: .systemFont(ofSize: 18, weight: .medium))
                    .textColor(.white)
                    .adjustsFontSizeToFitWidth(true)
                    .textAlignment(.center)
                    .inset(5)
                    .flex()
            },
            actionHandler: { completion, _, form in
                if form == .alert {
                    completion(.swipeFull {})
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
            let actionHandler: UIActionHandler = { action in
                if action.title == "Remind me later..." {
                    primaryMenuSwipeAction.manualHandlerAfter(afterHandler: .alert)
                } else {
                    primaryMenuSwipeAction.manualHandlerAfter(afterHandler: .close)
                }
            }
            return UIMenu(title: "Remind me", children: [
                UIAction(title: "Remind me in 1 hour", handler: actionHandler),
                UIAction(title: "Remind me tomorrow", handler: actionHandler),
                UIAction(title: "Remind me later...", handler: actionHandler),
            ])
        }
        primaryMenuSwipeAction.component = primaryMenuComponent
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
                completion(.swipeFull(removed))
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
