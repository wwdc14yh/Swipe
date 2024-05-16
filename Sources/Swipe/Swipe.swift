//  Created by y H on 2024/4/7.

import UIKit

public struct SwipeConfig {
    public static var `default` = SwipeConfig()

    /// Describes the transition style. Transition is the style of how the action buttons are exposed during the swipe.
    public enum LayoutEffect {
        /// The visible action area is equally divide between all action views.
        case border
        
        /// The visible action area is dragged, pinned to the any view, with each action view fully sized as it is exposed.
        case drag
        
        /// The visible action area sits behind the any view, pinned to the edge of the any scroll view, and is revealed as the any view is dragged aside.
        case `static`
    }
    
    public enum CornerRadius {
        case custom(CGFloat)
        case round
    }

    /// A Boolean value that indicates whether a full swipe automatically performs the first action. The default is true.
    public var allowsFullSwipe: Bool

    public var edgeBackgroundIgnoreSafeAreaInset: Bool

    public var feedbackEnable: Bool

    public var rubberBandEnable: Bool
    
    /// By using an exponent between 0 and 1, the view’s offset is moved less the further it is away from its resting position. Use a larger exponent for less movement and a smaller exponent for more movement.
    public var rubberBandFactor: CGFloat

    /// The layout effect. The style of how the action views are exposed during the swipe.
    public var layoutEffect: LayoutEffect

    public var itemSpacing: CGFloat
    public var gap: CGFloat

    public var defaultTransitionCurve: SwipeTransitionCurve
    public var defaultTransitionDuration: TimeInterval

    public var whenSwipeCloseOtherSwipeAction: Bool

    public var cornerRadius: CornerRadius
    public var clipsToBounds: Bool

    public init(
        allowsFullSwipe: Bool = true,
        edgeBackgroundIgnoreSafeAreaInset: Bool = true,
        feedbackEnable: Bool = true,
        rubberBandEnable: Bool = true,
        rubberBandFactor: CGFloat = 0.90,
        layoutEffect: LayoutEffect = .static,
        itemSpacing: CGFloat = 0,
        gap: CGFloat = 0,
        cornerRadius: CornerRadius = .custom(0),
        clipsToBounds: Bool = true,
        defaultTransitionCurve: SwipeTransitionCurve = .easeInOut,
        defaultTransitionDuration: TimeInterval = 0.3,
        whenSwipeCloseOtherSwipeAction: Bool = true
    ) {
        self.allowsFullSwipe = allowsFullSwipe
        self.edgeBackgroundIgnoreSafeAreaInset = edgeBackgroundIgnoreSafeAreaInset
        self.feedbackEnable = feedbackEnable
        self.rubberBandEnable = rubberBandEnable
        self.rubberBandFactor = rubberBandFactor
        self.layoutEffect = layoutEffect
        self.gap = gap
        self.itemSpacing = itemSpacing
        self.cornerRadius = cornerRadius
        self.clipsToBounds = clipsToBounds
        self.defaultTransitionCurve = defaultTransitionCurve
        self.defaultTransitionDuration = defaultTransitionDuration
        self.whenSwipeCloseOtherSwipeAction = whenSwipeCloseOtherSwipeAction
    }
}

public class SwipeView: UIView, UIGestureRecognizerDelegate {
    public var actions: [any SwipeAction] {
        set { configActions(with: newValue) }
        get { _actionsWrapper.map(\.action) }
    }

    public var config: SwipeConfig = .default {
        didSet { updateConfig() }
    }

    public let contentView: UIView

    // MARK: privates props

    private lazy var panRecognizer = SwipeGestureRecognizer(target: self, action: #selector(self.swipeGesture(_:)))

    private var scrollView: UIScrollView? { sequence(first: superview, next: { $0?.superview }).compactMap { $0 as? UIScrollView }.first }

    private var observation: NSKeyValueObservation?

    private var revealOffset: CGFloat = 0.0

    private var initialRevealOffset: CGFloat = 0.0

    private var leftActions: [ActionWrapper] = []

    private var rightActions: [ActionWrapper] = []

    private var _actionsWrapper: [ActionWrapper] = []

    private var leftSwipeActionsContainerView: SwipeContentWrapperView? = nil

    private var rightSwipeActionsContainerView: SwipeContentWrapperView? = nil

    public init(contentView: UIView) {
        self.contentView = contentView
        contentView.frame.origin = .zero
        super.init(frame: .zero)
        addSubview(contentView)
        panRecognizer.delegate = self
        panRecognizer.allowAnyDirection = true
        gestureRecognizers = [panRecognizer]
        updateConfig()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame.size = bounds.size
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.sizeThatFits(size)
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil, let scrollView else { return }
        observation?.invalidate()
        observation = nil
        observation = scrollView.observe(\.contentOffset) { [weak self] _, _ in
            guard let self else { return }
            closeSwipeAction(transition: .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve))
        }
    }

    func updateConfig() {
        clipsToBounds = config.clipsToBounds
    }

    var _animator: UIViewPropertyAnimator?

    func defaultTransitionCurve(xVelocity: CGFloat, from: CGFloat, to: CGFloat) -> SwipeTransitionCurve {
        let initialVelocity = SwipeTransitionCurve.initialAnimationVelocity(for: xVelocity, from: from, to: to)
        let parameters = UISpringTimingParameters(dampingRatio: 1, initialVelocity: CGVector(dx: initialVelocity, dy: 0))
        let animator = UIViewPropertyAnimator(duration: config.defaultTransitionDuration, timingParameters: parameters)
        _animator = animator
        return .custom(animator)
    }

    func configActions(with actions: [any SwipeAction]) {
        let actionsWrapper = actions.map { ActionWrapper(action: $0) }
        let leftActions = actionsWrapper.filter { $0.action.horizontalEdge == .left }
        let rightActions = actionsWrapper.filter { $0.action.horizontalEdge == .right }
        guard !self.actions.elementsEqual(actions, by: { $0.isSame($1) }) else {
            _actionsWrapper = actionsWrapper
            self.leftActions = leftActions
            self.rightActions = rightActions
            return
        }
        let wasEmpty = self.leftActions.isEmpty && self.rightActions.isEmpty
        let isEmpty = leftActions.isEmpty && rightActions.isEmpty
        _actionsWrapper = actionsWrapper
        self.leftActions = leftActions
        self.rightActions = rightActions
        if leftActions.isEmpty {
            if leftSwipeActionsContainerView != nil {
                panRecognizer.becomeCancelled()
                updateRevealOffsetInternal(offset: 0.0, xVelocity: 0, transition: .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve), anchorActionWrapper: nil)
            }
        }
        if rightActions.isEmpty {
            if rightSwipeActionsContainerView != nil {
                panRecognizer.becomeCancelled()
                updateRevealOffsetInternal(offset: 0.0, xVelocity: 0, transition: .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve), anchorActionWrapper: nil)
            }
        }
        if wasEmpty != isEmpty {
            panRecognizer.isEnabled = !isEmpty
        }
    }

    @objc func swipeGesture(_ recognizer: SwipeGestureRecognizer) {
        let xVelocity = recognizer.velocity(in: self).x
        switch recognizer.state {
        case .began:
            if config.whenSwipeCloseOtherSwipeAction {
                closeOtherSwipeAction(transition: .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve))
            }
            initialRevealOffset = revealOffset
        case .changed:
            var translation = recognizer.translation(in: self)
            translation.x += initialRevealOffset
            if leftActions.isEmpty {
                let offsetX = pow(abs(translation.x), 0.7)
                translation.x = min(offsetX, translation.x)
            }
            if rightActions.isEmpty {
                let offsetX = -pow(abs(translation.x), 0.7)
                translation.x = max(offsetX, translation.x)
            }
            if leftSwipeActionsContainerView == nil && CGFloat(0.0).isLess(than: translation.x) {
                setupLeftActionsContainerView()
            } else if rightSwipeActionsContainerView == nil && translation.x.isLess(than: 0.0) {
                setupRightActionsContainerView()
            }
            updateRevealOffsetInternal(offset: translation.x, xVelocity: xVelocity, transition: .immediate, anchorActionWrapper: nil)
        case .cancelled, .ended:
            if let leftSwipeActionsContainerView {
                let containerViewSize = CGSize(width: leftSwipeActionsContainerView.preferredWidth + config.gap, height: frame.height)
                var reveal = false
                if abs(xVelocity) < 100.0 {
                    if initialRevealOffset.isZero && revealOffset > 0.0 {
                        reveal = true
                    } else if revealOffset > containerViewSize.width {
                        reveal = true
                    } else {
                        reveal = false
                    }
                } else {
                    if xVelocity > 0.0 {
                        reveal = true
                    } else {
                        reveal = false
                    }
                }
                if reveal && leftSwipeActionsContainerView.isDisplayingExtendedAction {
                    reveal = false
                    handlerActionEvent(action: leftSwipeActionsContainerView.edgeAction, eventFrom: .expanded)
                } else {
                    let targetOffset = reveal ? containerViewSize.width : 0.0
                    updateRevealOffsetInternal(
                        offset: targetOffset,
                        xVelocity: xVelocity,
                        transition: .animated(duration: 0, curve: defaultTransitionCurve(xVelocity: xVelocity, from: revealOffset, to: containerViewSize.width)),
                        anchorActionWrapper: nil
                    ) { [unowned self] in
                        guard reveal, leftSwipeActionsContainerView.isDisplayingExtendedAction, revealOffset == targetOffset else { return }
                        leftSwipeActionsContainerView.resetExpandedState()
                    }
                }
            } else if let rightSwipeActionsContainerView {
                let containerViewSize = CGSize(width: rightSwipeActionsContainerView.preferredWidth + config.gap, height: frame.height)
                var reveal = false
                if abs(xVelocity) < 100.0 {
                    if initialRevealOffset.isZero && revealOffset < 0.0 {
                        reveal = true
                    } else if revealOffset < -containerViewSize.width {
                        reveal = true
                    } else {
                        reveal = false
                    }
                } else {
                    if xVelocity < 0.0 {
                        reveal = true
                    } else {
                        reveal = false
                    }
                }
                if reveal && rightSwipeActionsContainerView.isDisplayingExtendedAction {
                    reveal = false
                    handlerActionEvent(action: rightSwipeActionsContainerView.edgeAction, eventFrom: .expanded)
                } else {
                    let targetOffset = reveal ? -containerViewSize.width : 0.0
                    updateRevealOffsetInternal(
                        offset: targetOffset,
                        xVelocity: xVelocity,
                        transition: .animated(duration: 0, curve: defaultTransitionCurve(xVelocity: xVelocity, from: revealOffset, to: -containerViewSize.width)),
                        anchorActionWrapper: nil
                    ) { [unowned self] in
                        guard reveal, rightSwipeActionsContainerView.isDisplayingExtendedAction, revealOffset == targetOffset else { return }
                        rightSwipeActionsContainerView.resetExpandedState()
                    }
                }
            } else {
                updateRevealOffsetInternal(offset: 0, xVelocity: xVelocity, transition: .animated(duration: 0, curve: defaultTransitionCurve(xVelocity: xVelocity, from: revealOffset, to: 0)), anchorActionWrapper: nil)
            }
        default: break
        }
    }

    func updateRevealOffsetInternal(offset: CGFloat, xVelocity: CGFloat, transition: SwipeTransition, forceSwipeOffset: Bool = false, anchorActionWrapper: ActionWrapper?, completion: (() -> Void)? = nil) {
        revealOffset = offset
        var leftRevealCompleted = true
        var rightRevealCompleted = true
        let intermediateCompletion = {
            if leftRevealCompleted && rightRevealCompleted {
                completion?()
            }
        }
        transition.updateOriginX(with: contentView, originX: offset)
        if let leftSwipeActionsContainerView {
            leftRevealCompleted = false
            let containerViewSize = CGSize(width: leftSwipeActionsContainerView.preferredWidth, height: frame.height)
            let completion = {
                if CGFloat(offset).isLessThanOrEqualTo(0.0) {
                    leftSwipeActionsContainerView.removeFromSuperview()
                }
                leftRevealCompleted = true
                intermediateCompletion()
            }
            if CGFloat(offset).isLessThanOrEqualTo(0.0) {
                self.leftSwipeActionsContainerView = nil
                if config.rubberBandEnable && !forceSwipeOffset {
                    transition.updateOriginX(with: contentView, originX: offset)
                }
            } else {
                if config.rubberBandEnable && !forceSwipeOffset {
                    var distance: CGFloat {
                        let w = containerViewSize.width + leftSwipeActionsContainerView.expandedTriggerOffset
                        return offset - (offset >= w ? pow(offset - w, config.rubberBandFactor) : 0)
                    }
                    let distanceOffsetX = offset >= containerViewSize.width ? distance : offset
                    transition.updateOriginX(with: contentView, originX: distanceOffsetX)
                }
            }
            let containerViewFrame = CGRect(origin: .zero, size: CGSize(width: max(0, contentView.frame.minX - config.gap), height: containerViewSize.height))
            transition.updateFrame(with: leftSwipeActionsContainerView, frame: containerViewFrame) {
                guard $0 else { return }
                completion()
            }
            leftSwipeActionsContainerView.updateOffset(
                with: contentView.frame.minX - config.gap,
                sideInset: safeAreaInsets.left,
                xVelocity: xVelocity,
                forceSwipeOffset: forceSwipeOffset,
                anchorActionWrapper: anchorActionWrapper,
                transition: transition
            )
        }
        if let rightSwipeActionsContainerView {
            rightRevealCompleted = false
            let containerViewSize = CGSize(width: rightSwipeActionsContainerView.preferredWidth, height: frame.height)
            let completion = {
                if CGFloat(0.0).isLessThanOrEqualTo(offset) {
                    rightSwipeActionsContainerView.removeFromSuperview()
                }
                rightRevealCompleted = true
                intermediateCompletion()
            }
            if CGFloat(0.0).isLessThanOrEqualTo(offset) {
                self.rightSwipeActionsContainerView = nil
                if config.rubberBandEnable && !forceSwipeOffset {
                    transition.updateOriginX(with: contentView, originX: offset)
                }
            } else {
                if config.rubberBandEnable && !forceSwipeOffset {
                    var distance: CGFloat {
                        let w = containerViewSize.width + rightSwipeActionsContainerView.expandedTriggerOffset
                        return offset + (-offset >= w ? pow((-offset) - w, config.rubberBandFactor) : 0)
                    }
                    let distanceOffsetX = -offset >= containerViewSize.width ? distance : offset
                    transition.updateOriginX(with: contentView, originX: distanceOffsetX)
                }
            }
            let containerViewFrame = CGRect(
                origin: CGPoint(x: frame.width - abs(contentView.frame.minX) + config.gap, y: 0),
                size: CGSize(width: max(0, abs(contentView.frame.minX) - config.gap), height: containerViewSize.height)
            )
            transition.updateFrame(with: rightSwipeActionsContainerView, frame: containerViewFrame) {
                guard $0 else { return }
                completion()
            }
            rightSwipeActionsContainerView.updateOffset(
                with: abs(contentView.frame.minX) - config.gap,
                sideInset: safeAreaInsets.right,
                xVelocity: xVelocity,
                forceSwipeOffset: forceSwipeOffset,
                anchorActionWrapper: anchorActionWrapper,
                transition: transition
            )
        }
    }

    func setupLeftActionsContainerView() {
        if !leftActions.isEmpty {
            let actionsContainerView = SwipeContentWrapperView(actions: leftActions, config: config, horizontalEdge: .left, fixedHeight: bounds.height) { [weak self] action, event in
                guard let self else { return }
                handlerActionEvent(action: action, eventFrom: event)
            }
            leftSwipeActionsContainerView = actionsContainerView
            let size = CGSize(width: actionsContainerView.preferredWidth, height: bounds.height)
            actionsContainerView.frame = CGRect(origin: CGPoint(x: min(revealOffset - size.width, 0.0), y: 0.0), size: size)
            actionsContainerView.updateOffset(
                with: 0,
                sideInset: safeAreaInsets.left,
                xVelocity: 0,
                forceSwipeOffset: false,
                anchorActionWrapper: nil,
                transition: .immediate
            )
            actionsContainerView.actions.forEach { $0.action.willShow() }
            insertSubview(actionsContainerView, belowSubview: contentView)
        }
    }

    func setupRightActionsContainerView() {
        if !rightActions.isEmpty {
            let actionsContainerView = SwipeContentWrapperView(actions: rightActions, config: config, horizontalEdge: .right, fixedHeight: bounds.height) { [weak self] action, event in
                guard let self else { return }
                handlerActionEvent(action: action, eventFrom: event)
            }
            rightSwipeActionsContainerView = actionsContainerView
            let size = CGSize(width: actionsContainerView.preferredWidth, height: bounds.height)
            actionsContainerView.frame = CGRect(origin: CGPoint(x: bounds.width + max(revealOffset, -size.width), y: 0.0), size: size)
            actionsContainerView.updateOffset(
                with: 0,
                sideInset: safeAreaInsets.right,
                xVelocity: 0,
                forceSwipeOffset: false,
                anchorActionWrapper: nil,
                transition: .immediate
            )
            actionsContainerView.actions.forEach { $0.action.willShow() }
            insertSubview(actionsContainerView, belowSubview: contentView)
        }
    }

    func handlerActionEvent(action: any SwipeAction, eventFrom: SwipeActionEventFrom) {
        action.handlerAction(completion: { [weak self] afterHandler in
            guard let self else { return }
            self.afterHandler(with: afterHandler, action: action)
        }, eventFrom: eventFrom)
    }

    func afterHandler(with afterHandler: SwipeActionAfterHandler, action: (any SwipeAction)?) {
        let defaultTransition = SwipeTransition.animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve)
        guard let action, let actionWrapper = _actionsWrapper.first(where: { $0.action.isSame(action) }), let swipeContentWrapperView = actionWrapper.swipeContentWrapperView else {
            closeSwipeAction(transition: defaultTransition)
            return
        }
        switch afterHandler {
        case .close:
            closeSwipeAction(transition: defaultTransition)
        case let .expanded(completion):
            let xVelocity = panRecognizer.lastVelocity.x
            swipeContentWrapperView.clickedAction = action
            let offset = frame.width + config.gap
            updateRevealOffsetInternal(
                offset: swipeContentWrapperView.horizontalEdge.isLeft ? offset : -offset,
                xVelocity: xVelocity,
                transition: .animated(duration: 0, curve: defaultTransitionCurve(xVelocity: xVelocity, from: offset, to: swipeContentWrapperView.horizontalEdge.isLeft ? offset : -offset)),
                forceSwipeOffset: true,
                anchorActionWrapper: actionWrapper
            ) {
                completion?()
                self.updateRevealOffsetInternal(offset: 0, xVelocity: 0, transition: .immediate, anchorActionWrapper: nil)
                UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: nil)
            }
        case .alert:
            updateRevealOffsetInternal(offset: action.horizontalEdge.isLeft ? swipeContentWrapperView.preferredWidth : -swipeContentWrapperView.preferredWidth, xVelocity: 0, transition: defaultTransition, anchorActionWrapper: nil)
            swipeContentWrapperView.makeAlert(with: actionWrapper, transition: defaultTransition)
        case .hold:
            updateRevealOffsetInternal(offset: action.horizontalEdge.isLeft ? swipeContentWrapperView.preferredWidth : -swipeContentWrapperView.preferredWidth, xVelocity: 0, transition: defaultTransition, anchorActionWrapper: nil)
        }
    }

    public func manualHandlerAfter(afterHandler: SwipeActionAfterHandler, action: any SwipeAction) {
        self.afterHandler(with: afterHandler, action: action)
    }

    public func closeOtherSwipeAction(transition: SwipeTransition) {
        guard let scrollView else { return }
        let views = scrollView.allSubViewsOf(type: Self.self).filter { $0 != self }
        guard !views.isEmpty else { return }
        views.forEach { $0.closeSwipeAction(transition: transition) }
    }

    public func closeSwipeAction(transition: SwipeTransition) {
        updateRevealOffsetInternal(offset: 0.0, xVelocity: 0, transition: transition, anchorActionWrapper: nil)
    }

    public func openSwipeAction(with horizontalEdge: SwipeHorizontalEdge, transition: SwipeTransition) {
        if config.whenSwipeCloseOtherSwipeAction {
            closeOtherSwipeAction(transition: transition)
        }
        _animator?.stopAnimation(false)
        if horizontalEdge.isLeft, revealOffset <= 0 {
            if leftSwipeActionsContainerView == nil {
                setupLeftActionsContainerView()
                updateRevealOffsetInternal(offset: 1, xVelocity: 0, transition: .immediate, anchorActionWrapper: nil)
            }
            if let leftSwipeActionsContainerView {
                updateRevealOffsetInternal(offset: leftSwipeActionsContainerView.preferredWidth + config.gap, xVelocity: 0, transition: transition, anchorActionWrapper: nil)
            }
        } else if !horizontalEdge.isLeft, revealOffset >= 0 {
            if rightSwipeActionsContainerView == nil {
                setupRightActionsContainerView()
                updateRevealOffsetInternal(offset: -1, xVelocity: 0, transition: .immediate, anchorActionWrapper: nil)
            }
            if let rightSwipeActionsContainerView {
                updateRevealOffsetInternal(offset: -(rightSwipeActionsContainerView.preferredWidth + config.gap), xVelocity: 0, transition: transition, anchorActionWrapper: nil)
            }
        }
    }

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panRecognizer, panRecognizer.numberOfTouches == 0 {
            let translation = panRecognizer.velocity(in: panRecognizer.view)
            if abs(translation.y) > 4.0 && abs(translation.y) > abs(translation.x) * 2.5 {
                return false
            }
        }
        return true
    }

    public func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == panRecognizer {
            return true
        } else {
            return false
        }
    }

    deinit {
        observation?.invalidate()
        observation = nil
    }
}

final class SwipeGestureRecognizer: UIPanGestureRecognizer {
    public var validatedGesture = false
    public var firstLocation = CGPoint()

    public var allowAnyDirection = false
    public var lastVelocity = CGPoint()

    override public init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)

        if #available(iOS 13.4, *) {
            self.allowedScrollTypesMask = .continuous
        }

        maximumNumberOfTouches = 1
    }

    override public func reset() {
        super.reset()

        validatedGesture = false
    }

    public func becomeCancelled() {
        state = .cancelled
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        let touch = touches.first!
        firstLocation = touch.location(in: view)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        let location = touches.first!.location(in: view)
        let translation = CGPoint(x: location.x - firstLocation.x, y: location.y - firstLocation.y)

        if !validatedGesture {
            if !allowAnyDirection && translation.x > 0.0 {
                state = .failed
            } else if abs(translation.y) > 4.0 && abs(translation.y) > abs(translation.x) * 2.5 {
                state = .failed
            } else if abs(translation.x) > 4.0 && abs(translation.y) * 2.5 < abs(translation.x) {
                validatedGesture = true
            }
        }

        if validatedGesture {
            lastVelocity = velocity(in: view)
            super.touchesMoved(touches, with: event)
        }
    }
}

private extension UIView {
    func allSubViewsOf<T: UIView>(type _: T.Type) -> [T] {
        var all = [T]()
        func getSubview(view: UIView) {
            if let aView = view as? T {
                all.append(aView)
            }
            guard view.subviews.count > 0 else { return }
            view.subviews.forEach { getSubview(view: $0) }
        }
        getSubview(view: self)
        return all
    }
}
