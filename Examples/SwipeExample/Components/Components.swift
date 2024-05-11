//
//  Components.swift
//  SwipeExample
//
//  Created by y H on 2024/5/11.
//

import Swipe
import UIKit
import UIComponent
import UIComponentSwipe

extension SwipeActionComponent {
    static func rounded(horizontalEdge: SwipeHorizontalEdge, body: SwipeActionContent, backgroundColor: UIColor = .systemGroupedBackground, cornerRadius: CGFloat = 15) -> Self {
        self.init(
            identifier: UUID().uuidString,
            horizontalEdge: horizontalEdge
        ) {
            body
        } backgroundBuild: {
            ViewComponent()
                .backgroundColor(backgroundColor)
                .update {
                    $0.layer.cornerRadius = min(min($0.frame.height, $0.frame.width) / 2, cornerRadius)
                }
                .with(\.layer.cornerCurve, .continuous)
        } alertBuild: {
            Space()
        } configHighlightView: { highlightView, isHighlighted in
            UIView.performWithoutAnimation {
                highlightView.layer.cornerRadius = min(min(highlightView.frame.height, highlightView.frame.width) / 2, cornerRadius)
            }
            highlightView.backgroundColor = .black.withAlphaComponent(isHighlighted ? 0.3 : 0)
        } actionHandler: { completion, _, _ in
            completion(.swipeFull(nil))
        }
    }
}

struct Cell: ComponentBuilder {
    let title: String
    func build() -> some Component {
        HStack(alignItems: .center) {
            Text(title, font: .preferredFont(forTextStyle: .body))
        }
        .inset(15)
        .minSize(height: 44)
    }
}

struct Group: ComponentBuilder {
    let title: String
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let body: [any Component]
    init(title: String, backgroundColor: UIColor = .secondarySystemGroupedBackground, cornerRadius: CGFloat = 15, @ComponentArrayBuilder _ body: () -> [any Component]) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.body = body()
    }

    func build() -> some Component {
        VStack(alignItems: .stretch) {
            Text(title, font: UIFont.preferredFont(forTextStyle: .headline))
                .inset(top: 15, left: 15, bottom: 10, right: 0)
            VStack(alignItems: .stretch) {
                for (offset, component) in body.enumerated() {
                    var maskedCorners: CACornerMask {
                        if body.count == 1 {
                            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
                        } else if offset == body.count - 1 {
                            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        } else if offset == 0 {
                            return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                        } else {
                            return []
                        }
                    }
                    component
                        .view()
                        .clipsToBounds(!maskedCorners.isEmpty)
                        .with(\.layer.cornerRadius, maskedCorners.isEmpty ? 0 : cornerRadius)
                        .with(\.layer.cornerCurve, .continuous)
                        .with(\.layer.maskedCorners, maskedCorners)
                }
            }
            .background {
                ViewComponent()
                    .backgroundColor(backgroundColor)
                    .with(\.layer.cornerRadius, cornerRadius)
                    .with(\.layer.cornerCurve, .continuous)
            }
        }
        .size(width: .fill)
    }
}

struct EmailComponent: ComponentBuilder {
    let data: EmailData
    func build() -> some Component {
        HStack(alignItems: .stretch) {
            VStack(justifyContent: .start, alignItems: .center) {
                if data.unread {
                    Space(width: 10, height: 10)
                        .backgroundColor(UIColor(red: 0.008, green: 0.475, blue: 0.996, alpha: 1.0))
                        .roundedCorner()
                        .inset(top: 5)
                }
            }
            .size(width: 30)
            VStack(spacing: 2) {
                HStack {
                    Text(data.from, font: .systemFont(ofSize: 16, weight: .semibold), numberOfLines: 1, lineBreakMode: .byTruncatingTail)
                        .inset(right: 10)
                        .flex()
                    HStack(spacing: 5, alignItems: .center) {
                        Text(data.date.formatted(), font: .systemFont(ofSize: 16, weight: .regular))
                            .textColor(.secondaryLabel)
                        Image(systemName: "chevron.right")
                            .tintColor(.secondaryLabel)
                            .transform(.identity.scaledBy(x: 0.8, y: 0.8))
                    }
                }
                Text(data.subject, font: .systemFont(ofSize: 15, weight: .regular), numberOfLines: 1, lineBreakMode: .byTruncatingTail)
                Text(data.body, font: .systemFont(ofSize: 15, weight: .regular), numberOfLines: 2, lineBreakMode: .byTruncatingTail)
                    .textColor(.secondaryLabel)
            }
            .flex()
        }
        .size(width: .fill)
        .inset(left: 0, rest: 10)
        .animator(TransformAnimator())
        .id(data.id)
    }
}

struct SwipeActionContent: ComponentBuilder {
    let image: UIImage?
    let text: String
    let alignment: Alignment
    let tintColor: UIColor

    enum Alignment {
        case ttb
        case ltr
    }

    var combineComponent: [any Component] {
        func build(@ComponentArrayBuilder _ build: () -> [any Component]) -> [any Component] {
            return build()
        }
        return build {
            if let image {
                Image(image)
                    .tintColor(tintColor)
            }
            if !text.isEmpty {
                Text(text)
                    .font(.systemFont(ofSize: 16))
                    .textColor(tintColor)
            }
        }
    }

    func build() -> some Component {
        ZStack {
            switch alignment {
            case .ttb:
                VStack(spacing: 2, alignItems: .center) { combineComponent }
            case .ltr:
                HStack(spacing: 2, alignItems: .center) { combineComponent }
            }
        }
        .inset(h: 20)
    }
}
