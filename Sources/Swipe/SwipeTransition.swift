//  Created by y H on 2024/4/11.

import UIKit

public enum SwipeTransition {
    case immediate
    case animated(duration: TimeInterval, curve: SwipeTransitionCurve)

    var isAnimated: Bool {
        if case .immediate = self {
            return false
        } else {
            return true
        }
    }

    var duration: TimeInterval {
        switch self {
        case .immediate:
            return 0.0
        case let .animated(duration, _):
            return duration
        }
    }

    static func defaultAnimation(_ config: SwipeConfig) -> SwipeTransition {
        .animated(duration: config.defaultTransitionDuration, curve: config.defaultTransitionCurve)
    }
}

public enum SwipeTransitionCurve: Equatable, Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case spring(damping: CGFloat, initialVelocity: CGVector)
    case custom(UIViewPropertyAnimator)

    static func initialAnimationVelocity(for gestureXvelocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat {
        var animationXvelocity: CGFloat = 0
        let xDistance = targetValue - currentValue
        if xDistance != 0 {
            animationXvelocity = gestureXvelocity / xDistance
        }
        return min(10, max(-10, animationXvelocity))
    }

    @MainActor
    func animator(duration: TimeInterval) -> UIViewPropertyAnimator {
        switch self {
        case .linear:
            return UIViewPropertyAnimator(duration: duration, curve: .linear)
        case .easeInOut:
            return UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
        case .easeIn:
            return UIViewPropertyAnimator(duration: duration, curve: .easeIn)
        case .easeOut:
            return UIViewPropertyAnimator(duration: duration, curve: .easeOut)
        case let .spring(damping, initialVelocity):
            return UIViewPropertyAnimator(duration: duration, timingParameters: UISpringTimingParameters(dampingRatio: damping, initialVelocity: initialVelocity))
        case let .custom(animator):
            return animator
        }
    }
}

extension SwipeTransition {
    @MainActor
    @discardableResult
    func update(animation: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator? {
        switch self {
        case .immediate:
            UIView.performWithoutAnimation(animation)
            if let completion = completion {
                completion(true)
            }
        case let .animated(duration, curve):
            let animator = curve.animator(duration: duration)
            animator.addAnimations(animation)
            animator.addCompletion { position in
                if let completion = completion {
                    completion(position == .end)
                }
            }
            animator.startAnimation()
            return animator
        }
        return nil
    }

    @MainActor
    @discardableResult
    func updateOriginX(with view: UIView, originX: CGFloat, completion _: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator? {
        update { view.frame.origin.x = originX }
    }

    @MainActor
    @discardableResult
    func updateFrame(with view: UIView, frame: CGRect, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator? {
        if view.frame.equalTo(frame) {
            completion?(true)
            return nil
        } else {
            return update(animation: {
                view.frame = frame
            }, completion: completion)
        }
    }
}

extension UISpringTimingParameters {
    /// A design-friendly way to create a spring timing curve.
    ///
    /// - Parameters:
    ///   - damping: The 'bounciness' of the animation. Value must be between 0 and 1.
    ///   - response: The 'speed' of the animation.
    ///   - initialVelocity: The vector describing the starting motion of the property. Optional, default is `.zero`.
    convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
        let stiffness = pow(2 * .pi / response, 2)
        let damp = 4 * .pi * damping / response
        self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
}
