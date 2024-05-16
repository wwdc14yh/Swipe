//  Created by y H on 2024/4/11.

import UIKit

class ActionWrapper {
    let action: any SwipeAction
    private(set) var didRender: Bool = false
    lazy var contentView: UIView = {
        didRender = true
        return action.makeCotnentView()
    }()

    var swipeContentWrapperView: SwipeContentWrapperView? {
        guard didRender else { return nil }
        return sequence(first: contentView, next: { $0?.superview }).compactMap { $0 as? SwipeContentWrapperView }.first
    }
    
    init(action: any SwipeAction) {
        self.action = action
    }
}

class ActionWrapperView: UIView {
    var isHighlighted = false {
        didSet { setHighlighted(isHighlighted, transition: .animated(duration: 0.5, curve: .easeOut)) }
    }

    let highlightedMaskView = UIView()
    let contentView: UIView
    let actionWrapper: ActionWrapper
    let handlerTap: (any SwipeAction) -> Void
    var action: any SwipeAction { actionWrapper.action }
    
    init(actionWrapper: ActionWrapper, customView: UIView? = nil, handlerTap: @escaping (any SwipeAction) -> Void) {
        self.actionWrapper = actionWrapper
        contentView = customView ?? actionWrapper.contentView
        self.handlerTap = handlerTap
        super.init(frame: .zero)

        addSubview(contentView)
        addSubview(highlightedMaskView)
        highlightedMaskView.backgroundColor = .clear
        highlightedMaskView.isUserInteractionEnabled = false

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handlerTap))
        addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHighlighted(_ isHighlighted: Bool, transition: SwipeTransition) {
        transition.update {
            self.action.configHighlightView(with: self.highlightedMaskView, isHighlighted: isHighlighted)
        }
    }

    @objc private func _handlerTap() {
        handlerTap(action)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        highlightedMaskView.frame = bounds
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.sizeThatFits(size)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        isHighlighted = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        isHighlighted = false
    }
}

class SwipeContentWrapperView: UIView {
    typealias ActionTapHandler = (_ action: any SwipeAction, _ eventForm: SwipeActionEventFrom) -> Void

    let actions: [ActionWrapper]
    let horizontalEdge: SwipeHorizontalEdge
    let config: SwipeConfig
    var totalItemSpacing: CGFloat {
        CGFloat(actions.count - 1) * config.itemSpacing
    }

    var preferredWidth: CGFloat {
        preferredContentWidth + sideInset + totalItemSpacing
    }

    var preferredWithoutSideInsetContentWidth: CGFloat {
        preferredContentWidth + totalItemSpacing
    }

    var preferredWithoutItemSpacingContentWidth: CGFloat {
        preferredContentWidth + sideInset
    }

    var expandedTriggerOffset: CGFloat {
        config.allowsFullSwipe ? (actions.count > 2 ? 40 : 60) : 0
    }

    var isDisplayingExtendedAction: Bool { isExpanded }

    var edgeView: UIView {
        guard let view = isLeft ? views.first : views.last else { fatalError() }
        return view
    }

    var edgeViewFrame: CGRect {
        guard let frame = isLeft ? viewFrames.first : viewFrames.last else { fatalError() }
        return frame
    }

    var edgeSize: CGFloat {
        guard let size = isLeft ? sizes.first : sizes.last else { fatalError() }
        return size
    }

    var edgeActionWrapper: ActionWrapper {
        guard let actionWrapper = isLeft ? actions.first : actions.last else { fatalError() }
        return actionWrapper
    }

    var edgeAction: any SwipeAction {
        edgeActionWrapper.action
    }

    let preferredContentWidth: CGFloat
    var clickedAction: (any SwipeAction)? = nil

    private var isLeft: Bool
    private var viewFrames: [CGRect]
    private let views: [ActionWrapperView]
    private let sizes: [CGFloat]
    private let actionTapHandler: ActionTapHandler
    private var sideInset: CGFloat = 0
    private var offset: CGFloat = 0
    private var alertContext: (actionWrapper: ActionWrapper, alertWrapView: ActionWrapperView)? = nil
    private var isExpanded = false
    private var isComplete = false
    private var expandedView: UIView?
    private var animator: UIViewPropertyAnimator?
    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    init(
        actions: [ActionWrapper],
        config: SwipeConfig,
        horizontalEdge: SwipeHorizontalEdge,
        fixedHeight: CGFloat,
        actionTapHandler: @escaping ActionTapHandler
    ) {
        let isLeft = horizontalEdge.isLeft
        let actions = isLeft ? actions.reversed() : actions
        let views = actions.map {
            ActionWrapperView(actionWrapper: $0, handlerTap: { actionTapHandler($0, .tap) })
        }
        self.actionTapHandler = actionTapHandler
        let sizes = views.map { floor($0.sizeThatFits(CGSize(width: .infinity, height: fixedHeight)).width) }
        self.sizes = sizes
        self.views = views
        viewFrames = .init(repeating: .zero, count: views.count)
        self.actions = actions
        self.config = config
        self.isLeft = isLeft
        preferredContentWidth = sizes.reduce(0) { $0 + $1 }
        self.horizontalEdge = horizontalEdge
        super.init(frame: .zero)
        setup(fixedHeight: fixedHeight)
    }

    private func setup(fixedHeight: CGFloat) {
        (isLeft ? views.reversed() : views).forEach { addSubview($0) }
        clipsToBounds = true
        switch config.cornerRadius {
        case let .custom(cGFloat):
            layer.cornerRadius = cGFloat
        case .round:
            layer.cornerRadius = fixedHeight / 2
        }
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeAlert(with actionWrapper: ActionWrapper, transition: SwipeTransition) {
        guard let index = actions.firstIndex(where: { $0.action.isSame(actionWrapper.action) }) else { return }
        let subview = views[index]
        let alertView = ActionWrapperView(actionWrapper: actionWrapper, customView: actionWrapper.action.makeAlertView()) { [unowned self] in
            actionTapHandler($0, .alert)
            cancelAlert(transition: transition)
        }
        alertView.frame = subview.frame
        addSubview(alertView)
        alertView.layoutIfNeeded()
        UIView.transition(with: self, duration: 0.2, options: [.transitionCrossDissolve], animations: nil)
        transition.update {
            alertView.frame = self.bounds
        }
        alertContext = (actionWrapper, alertView)
    }
    
    func makeExpandedView(with actionWrapper: ActionWrapper, frame: CGRect) -> UIView? {
        let action = actionWrapper.action
        guard let expandedView = action.makeExpandedView() else { return nil }
        expandedView.frame = frame
        insertSubview(expandedView, aboveSubview: edgeView)
        expandedView.layoutIfNeeded()
        if action.isEnableFadeTransitionAddedExpandedView {
            UIView.transition(with: expandedView, duration: 0.1, options: [.transitionCrossDissolve], animations: nil)
        }
        return expandedView
    }
    
    private func cancelAlert(transition: SwipeTransition) {
        guard let alertContext else { return }
        self.alertContext = nil
        transition.update {
            alertContext.alertWrapView.alpha = 0
        } completion: { _ in
            alertContext.alertWrapView.removeFromSuperview()
        }
    }

    func updateOffset(with offset: CGFloat, sideInset: CGFloat, xVelocity: CGFloat, forceSwipeOffset: Bool, anchorActionWrapper: ActionWrapper?, transition: SwipeTransition) {
        self.sideInset = sideInset
        self.offset = offset
        self.isComplete = preferredWidth >= offset
        let factor: CGFloat = abs(offset / preferredWidth)
        let boundarySwipeActionFactor: CGFloat = 1.0 + expandedTriggerOffset / preferredWidth
        var totalOffsetX: CGFloat = 0
        var previousFrame = CGRect.zero
        let previousFrames = viewFrames
        for (index, (subview, subviewSize)) in zip(views, sizes).enumerated() {
            // layout subviews
            let gap = index == 0 ? 0 : config.itemSpacing
            let fixedWidth = subviewSize + (edgeView == subview ? sideInset : 0)
            let offsetX: CGFloat
            if isLeft {
                if config.layoutEffect == .drag {
                    offsetX = index == 0 ? floatInterpolate(factor: min(1, factor), start: -preferredWithoutSideInsetContentWidth, end: 0) : previousFrame.maxX
                } else if config.layoutEffect == .border {
                    offsetX = floatInterpolate(factor: min(1, factor), start: previousFrame.minX - (index == 0 ? fixedWidth : -sideInset), end: previousFrame.maxX)
                } else if config.layoutEffect == .static {
                    offsetX = previousFrame.maxX
                } else {
                    fatalError()
                }
            } else {
                if config.layoutEffect == .drag {
                    offsetX = previousFrame.maxX
                } else if config.layoutEffect == .border {
                    offsetX = floatInterpolate(factor: min(1, factor), start: previousFrame.minX, end: previousFrame.maxX)
                } else if config.layoutEffect == .static {
                    offsetX = index == 0 ? floatInterpolate(factor: min(1, factor), start: -preferredWidth, end: 0) : previousFrame.maxX
                }  else {
                    fatalError()
                }
            }
            let flexbleWidth = max(fixedWidth, (((offset - totalItemSpacing) / preferredWithoutItemSpacingContentWidth) * fixedWidth))
            let subviewFrame = CGRect(x: offsetX + gap, y: 0, width: flexbleWidth, height: frame.height)
            transition.update {
                subview.frame = subviewFrame
            }
            previousFrame = subviewFrame
            totalOffsetX += fixedWidth
        }
        let actionWrapper: ActionWrapper?
        var swipeFullTransition = transition
        var isExpanded = false
        if factor > boundarySwipeActionFactor, config.allowsFullSwipe {
            isExpanded = true
            actionWrapper = anchorActionWrapper ?? edgeActionWrapper
        } else {
            actionWrapper = nil
        }

        let expandedViewFrame: CGRect = isExpanded ? CGRect(origin: .zero, size: CGSize(width: offset, height: frame.height)) : edgeView.frame
        if self.isExpanded != isExpanded {
            swipeFullTransition = transition.isAnimated ? transition : .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve)
            if expandedView == nil, config.allowsFullSwipe, let actionWrapper, let index = actions.firstIndex(where: { $0.action.isSame(actionWrapper.action) }) {
                let initialExpandedViewFrame: CGRect
                if forceSwipeOffset {
                    if let alertContext {
                        initialExpandedViewFrame = alertContext.alertWrapView.frame
                    } else {
                        initialExpandedViewFrame = previousFrames[index]
                    }
                } else {
                    initialExpandedViewFrame = views[index].frame
                }
                expandedView = makeExpandedView(with: actionWrapper, frame: initialExpandedViewFrame)
            }
        }
        handlerExpanded(transition: swipeFullTransition,
                        additive: !transition.isAnimated,
                        expandedViewFrame: expandedViewFrame,
                        isExpanded: isExpanded,
                        anchorActionWrapper: actionWrapper)
        cancelAlert(transition: transition.isAnimated ? transition : .animated(duration: 0.15, curve: .easeInOut))
    }

    func handlerExpanded(transition: SwipeTransition, additive: Bool, expandedViewFrame: CGRect, isExpanded: Bool, anchorActionWrapper: ActionWrapper?) {
        guard let expandedView, config.allowsFullSwipe else { return }
        var animateAdditive = false
        var transition = transition
        if additive && transition.isAnimated && self.isExpanded != isExpanded {
            animateAdditive = true
            transition = .animated(duration: transition.duration - (transition.duration * 0.1), curve: .easeInOut)
        }
        if animateAdditive {
            if config.feedbackEnable {
                feedbackGenerator.impactOccurred()
                feedbackGenerator.prepare()
            }
        }
        transition.updateFrame(with: expandedView, frame: expandedViewFrame)
        self.isExpanded = isExpanded
    }

    func resetExpandedState() {
        guard let expandedView, isComplete else { return }
        expandedView.removeFromSuperview()
        self.expandedView = nil
        UIView.transition(with: expandedView, duration: 0.1, options: [.transitionCrossDissolve], animations: nil)
    }

    func floatInterpolate(factor: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        return start + (end - start) * factor
    }

    func translateRange(factor: CGFloat, startFactor: CGFloat, endFactor: CGFloat, startValue: CGFloat, endValue: CGFloat) -> CGFloat {
        let factorRange = endFactor - startFactor
        let valueRange = endValue - startValue
        return (factor - startFactor) * valueRange / factorRange + startValue
    }
}
