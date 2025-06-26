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
    init(
        horizontalEdge: SwipeHorizontalEdge,
        body: SwipeActionContent,
        expanded: SwipeActionContent? = nil,
        backgroundColor: UIColor = .systemGroupedBackground
    ) {
        self.init(identifier: UUID().uuidString,
                  horizontalEdge: horizontalEdge,
                  backgroundColor: backgroundColor,
                  body: body,
                  expanded: expanded,
                  actionHandler: { completion, _, _ in
            completion(.expanded())
        })
    }
}

struct Cell: ComponentBuilder {
    
    let title: String
    let subtitle: String
    init(title: String = "", subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }
    
    @MainActor
    @preconcurrency
    public func build() -> some Component {
        VStack(spacing: 5, alignItems: .start) {
            if !title.isEmpty {
                Text(title, font: .systemFont(ofSize: 18, weight: .semibold))
            }
            if !subtitle.isEmpty {
                Text(subtitle, font: .systemFont(ofSize: 15, weight: .regular))
                    .textColor(.secondaryLabel)
            }
        }
        .inset(15)
        .minSize(height: 44)
        .id(title + subtitle)
        .reuseStrategy(.key("cell"))
    }
}

struct Group: ComponentBuilder {
    let title: any Component
    let footnode: (any Component)?
    let backgroundColor: UIColor
    let cornerRadius: CGFloat
    let body: [any Component]

    init(title: any Component, footnode: any Component, backgroundColor: UIColor, cornerRadius: CGFloat, body: [any Component]) {
        self.title = title
        self.footnode = footnode
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.body = body
    }

    init(
        title: String,
        footnote: String? = nil,
        backgroundColor: UIColor = .secondarySystemGroupedBackground,
        cornerRadius: CGFloat = 15,
        @ComponentArrayBuilder _ body: () -> [any Component]
    ) {
        var footnode: (any Component)? {
            guard let footnote else { return nil }
            return Text(footnote, font: UIFont.preferredFont(forTextStyle: .footnote))
                .textColor(.secondaryLabel)
        }
        self.title = Text(title, font: UIFont.systemFont(ofSize: 20, weight: .bold))
        self.footnode = footnode
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.body = body()
    }

    @MainActor
    @preconcurrency
    func build() -> some Component {
        VStack(alignItems: .stretch) {
            title
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
                        .eraseToAnyComponent()
                        .clipsToBounds(true)
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
            if let footnode {
                footnode
                    .inset(top: 15, left: 15, bottom: 10, right: 0)
            }
        }
        .size(width: .fill)
    }
}

struct EmailComponent: ComponentBuilder {
    let data: EmailData
    
    @MainActor
    @preconcurrency
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
        .id(data.id)
        .reuseStrategy(.key("email"))
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

    @MainActor
    @preconcurrency
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

    @MainActor
    @preconcurrency
    func build() -> some Component {
        ZStack {
            switch alignment {
            case .ttb:
                VStack(spacing: 2, alignItems: .center) { combineComponent }
            case .ltr:
                HStack(spacing: 2, alignItems: .center) { combineComponent }
            }
        }
        .inset(h: 25)
    }
}
