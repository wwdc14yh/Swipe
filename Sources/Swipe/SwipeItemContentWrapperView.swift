//  Created by y H on 2024/5/18.


import UIKit

final class SwipeItemContentWrapperView: UIView {
    
    let backgroundView: UIView
    let contentView: UIView
    let highlightView: UIView
    let wrapperAction: SwipeActionWrapper
    let handlerTap: (any SwipeAction) -> Void
    let config: SwipeConfig
    private var animator: UIViewPropertyAnimator? = nil
    
    init(contentView: UIView, wrapperAction: SwipeActionWrapper, config: SwipeConfig, handlerTap: @escaping (any SwipeAction) -> Void) {
        self.highlightView = UIView()
        self.contentView = contentView
        self.wrapperAction = wrapperAction
        self.backgroundView = wrapperAction.backgroundView
        self.config = config
        self.handlerTap = handlerTap
        super.init(frame: .zero)
        addSubview(backgroundView)
        addSubview(contentView)
        addSubview(highlightView)
        highlightView.backgroundColor = .clear
        highlightView.isUserInteractionEnabled = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handlerTap))
        addGestureRecognizer(tapGestureRecognizer)
        backgroundView.clipsToBounds = true
        highlightView.clipsToBounds = true
        layer.cornerCurve = .continuous
        highlightView.layer.cornerCurve = .continuous
        backgroundView.layer.cornerCurve = .continuous
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        contentView.sizeThatFits(size)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: bounds.width + 100, height: bounds.height))
        highlightView.frame = bounds
        let fitSize = sizeThatFits(bounds.size)
        contentView.frame = CGRect(origin: .zero, size: CGSize(width: fitSize.width, height: floor(bounds.height)))
        if config.cornerRadiusType == .unit {
            var backgroundView = backgroundView
            if clipsToBounds {
                backgroundView = self
            }
            switch config.cornerRadius {
            case .custom(let cGFloat):
                backgroundView.layer.cornerRadius = cGFloat
            case .round:
                backgroundView.layer.cornerRadius = bounds.height / 2
            }
            highlightView.layer.cornerRadius = backgroundView.layer.cornerRadius
        }
    }
    
    @objc private func _handlerTap() {
        handlerTap(wrapperAction.action)
    }
    
    private func touchDown() {
        animator?.stopAnimation(true)
        setHighlighted(true, transition: .immediate)
    }
    
    private func touchUp() {
        setHighlighted(false, transition: .animated(duration: 0.5, curve: .easeOut))
    }
    
    func setHighlighted(_ isHighlighted: Bool, transition: SwipeTransition) {
        animator = transition.update {
            self.wrapperAction.action.configHighlightView(with: self.highlightView, isHighlighted: isHighlighted)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchDown()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchUp()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchUp()
    }
    
}
