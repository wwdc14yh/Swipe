//  Created by y H on 2024/5/18.

import UIKit

final class SwipeContentWrapperView: UIView {
    typealias ActionTapHandler = (_ action: any SwipeAction, _ eventForm: SwipeActionEventFrom) -> Void
    
    /// Context properties
    let horizontalEdgeWrapperActions: [SwipeActionWrapper]
    let horizontalEdge: SwipeHorizontalEdge
    let config: SwipeConfig
    let actionTapHandler: ActionTapHandler
    let preferredContentWidth: CGFloat

    /// Store properties
    private var viewFrames: [CGRect]
    private let views: [SwipeItemContentWrapperView]
    private let sizes: [CGFloat]
    private var sideInset: CGFloat = 0
    private var isExpanded = false
    private var expandedView: UIView?
    private var alertContext: (actionWrapper: SwipeActionWrapper, alertWrapView: SwipeItemContentWrapperView)? = nil
    private lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Computed properties
    var isLeft: Bool { horizontalEdge.isLeft }
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

    var edgeActionWrapper: SwipeActionWrapper {
        guard let actionWrapper = isLeft ? horizontalEdgeWrapperActions.first : horizontalEdgeWrapperActions.last else { fatalError() }
        return actionWrapper
    }

    var edgeAction: any SwipeAction {
        edgeActionWrapper.action
    }

    var totalItemSpacing: CGFloat {
        CGFloat(horizontalEdgeWrapperActions.count - 1) * config.itemSpacing
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
        config.allowsFullSwipe ? (horizontalEdgeWrapperActions.count > 2 ? 40 : 60) : 0
    }
    
    var isDisplayingExtendedAction: Bool { isExpanded }

    init(horizontalEdgeActions: [SwipeActionWrapper], horizontalEdge: SwipeHorizontalEdge, config: SwipeConfig, actionTapHandler: @escaping ActionTapHandler) {
        let views = horizontalEdgeActions.map {
            SwipeItemContentWrapperView(
                contentView: $0.contentView,
                wrapperAction: $0,
                config: config,
                handlerTap: { actionTapHandler($0, .tap) }
            )
        }
        let sizes = views.map { floor($0.sizeThatFits(CGSize(width: .infinity, height: CGFloat.infinity)).width) }
        self.sizes = sizes
        self.views = views
        preferredContentWidth = sizes.reduce(0) { $0 + $1 }
        self.horizontalEdgeWrapperActions = horizontalEdgeActions
        self.horizontalEdge = horizontalEdge
        self.config = config
        self.actionTapHandler = actionTapHandler
        viewFrames = .init(repeating: .zero, count: views.count)
        super.init(frame: .zero)
        (isLeft ? views.reversed() : views).forEach { addSubview($0) }
        views
            .enumerated()
            .forEach { $1.clipsToBounds = ($0 != (views.count - 1))  }
        clipsToBounds = true
        self.layer.cornerCurve = .continuous
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch config.cornerRadius {
        case let .custom(cGFloat):
            layer.cornerRadius = cGFloat
        case .round:
            layer.cornerRadius = bounds.height / 2
        }
    }
    
    func makeAlert(with actionWrapper: SwipeActionWrapper, transition: SwipeTransition) {
        guard let index = horizontalEdgeWrapperActions.firstIndex(where: { $0.action.isSame(actionWrapper.action) }) else { return }
        let subviewFrame = viewFrames[index]
        let copySwipeActionWrapper = SwipeActionWrapper(action: actionWrapper.action)
        let alertView = SwipeItemContentWrapperView(contentView: actionWrapper.action.makeAlertView(),
                                                    wrapperAction: copySwipeActionWrapper,
                                                    config: config) { [unowned self] in
            actionTapHandler($0, .alert)
            cancelAlert(transition: transition)
        }
        alertView.frame = subviewFrame
        addSubview(alertView)
        alertView.setNeedsLayout()
        alertView.layoutIfNeeded()
        UIView.transition(with: self, duration: 0.1, options: [.transitionCrossDissolve], animations: nil)
        transition.update {
            alertView.frame = self.bounds
        }
        alertContext = (actionWrapper, alertView)
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

    private func makeExpandedView(with expandedActionWrapper: SwipeActionWrapper, frame: CGRect) -> UIView? {
        guard let expandedView = expandedActionWrapper.action.makeExpandedView() else {
            guard let offset = horizontalEdgeWrapperActions.firstIndex(where: { $0.action.isSame(expandedActionWrapper.action) }) else { return nil }
            let expandedView = views[offset]
            bringSubviewToFront(expandedView)
            return expandedView
        }
        let copyExpandedActionWrapper = SwipeActionWrapper(action: expandedActionWrapper.action)
        let itemContentWrapperView = SwipeItemContentWrapperView(contentView: expandedView, wrapperAction: copyExpandedActionWrapper, config: config, handlerTap: {_ in})
        itemContentWrapperView.frame = frame
        insertSubview(itemContentWrapperView, aboveSubview: edgeView)
        itemContentWrapperView.layoutIfNeeded()
        itemContentWrapperView.contentView.alpha = 0
        if expandedActionWrapper.action.isEnableFadeTransitionAddedExpandedView {
            SwipeTransition.animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve).update {
                itemContentWrapperView.contentView.alpha = 1
            }
        }
        return itemContentWrapperView
    }

    func updateOffset(_ offset: CGFloat, sideInset: CGFloat, forceSwipeOffset: Bool, anchorActionWrapper: SwipeActionWrapper?, transition: SwipeTransition) {
        cancelAlert(transition: .defaultAnimation(config))
        self.sideInset = sideInset
        let factor: CGFloat = abs(offset / preferredWidth)
        let boundarySwipeActionFactor: CGFloat = 1.0 + expandedTriggerOffset / preferredWidth
        var isExpanded = false
        if factor > boundarySwipeActionFactor, config.allowsFullSwipe {
            isExpanded = true
        }
        var expandedTransition = transition
        let expandedActionWrapper = anchorActionWrapper ?? edgeActionWrapper
        if self.isExpanded != isExpanded {
            expandedTransition = transition.isAnimated ? transition : .defaultAnimation(config)
            if expandedView == nil, config.allowsFullSwipe, let index = horizontalEdgeWrapperActions.firstIndex(where: { $0.action.isSame(expandedActionWrapper.action) }) {
                var initialExpandedViewFrame: CGRect {
                    if forceSwipeOffset {
                        if let alertContext {
                            return alertContext.alertWrapView.frame
                        }
                    }
                    return viewFrames[index]
                }
                expandedView = makeExpandedView(with: expandedActionWrapper, frame: initialExpandedViewFrame)
            }
        }
        updateFrames(offset, 
                     additive: !transition.isAnimated,
                     isExpanded: isExpanded, 
                     expandedActionWrapper: expandedActionWrapper,
                     transition: expandedTransition)
    }

    func updateFrames(_ offset: CGFloat, additive: Bool, isExpanded: Bool, expandedActionWrapper: SwipeActionWrapper, transition: SwipeTransition) {
        let backupTransition = transition
        var expandedTransition = transition
        if additive && transition.isAnimated && self.isExpanded != isExpanded {
            expandedTransition = .defaultAnimation(config)
            if config.feedbackEnable {
                feedbackGenerator.impactOccurred()
                feedbackGenerator.prepare()
            }
        }
        /// Handler Frames
        var totalOffsetX: CGFloat = 0
        var previousFrame = CGRect.zero
        let factor: CGFloat = abs(offset / preferredWidth)
        for (index, (subview, subviewSize)) in zip(views, sizes).enumerated() {
            let itemSpacing = index == 0 ? 0 : config.itemSpacing
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
                } else {
                    fatalError()
                }
            }
            let flexbleWidth = max(fixedWidth, (((offset - totalItemSpacing) / preferredWithoutItemSpacingContentWidth) * fixedWidth))
            let subviewFrame = CGRect(x: offsetX + itemSpacing, y: 0, width: flexbleWidth, height: frame.height)
            viewFrames[index] = subviewFrame
            
            /// Update frame
            if let expandedView {
                let expandedFrame: CGRect
                if expandedView == subview {
                    expandedFrame = isExpanded ? CGRect(origin: .zero, size: CGSize(width: offset, height: bounds.height)) : subviewFrame
                } else if let expandedIndex = horizontalEdgeWrapperActions.firstIndex(where: { $0.action.isSame(expandedActionWrapper.action) }) {
                    expandedFrame = isExpanded ? CGRect(origin: .zero, size: CGSize(width: offset, height: bounds.height)) : viewFrames[expandedIndex]
                } else {
                    expandedFrame = isExpanded ? CGRect(origin: .zero, size: CGSize(width: offset, height: bounds.height)) : edgeViewFrame
                }
                expandedTransition.update { [unowned self] in
                    if !views.contains(where: { $0 == expandedView }) {
                        expandedView.frame = expandedFrame
                    } else {
                        if expandedView != subview {
                            subview.frame = subviewFrame
                        } else {
                            expandedView.frame = expandedFrame
                        }
                    }
                }
                if expandedView != subview {
                    expandedTransition.updateFrame(with: subview, frame: subviewFrame)
                } else {
                    expandedTransition.updateFrame(with: expandedView, frame: expandedFrame)
                }
            } else {
                backupTransition.updateFrame(with: subview, frame: subviewFrame)
            }
            
            previousFrame = subviewFrame
            totalOffsetX += fixedWidth
        }
        self.isExpanded = isExpanded
    }

    func resetExpandedState() {
        if !isExpanded, let expandedView {
            if !views.contains(where: { $0 == expandedView }) {
                expandedView.removeFromSuperview()
                UIView.transition(with: self, duration: 0.1, options: [.transitionCrossDissolve], animations: nil)
            }
            self.expandedView = nil
        }
    }
    
    func floatInterpolate(factor: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        return start + (end - start) * factor
    }
}
