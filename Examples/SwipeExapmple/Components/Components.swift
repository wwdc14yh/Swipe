//
//  Components.swift
//  SwipeExapmple
//
//  Created by y H on 2024/5/11.
//

import UIKit
import UIComponent

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
    let body: [any Component]
    init(title: String, @ComponentArrayBuilder _ body: () -> [any Component]) {
        self.title = title
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
                    if maskedCorners.isEmpty {
                        component
                    } else {
                        component
                            .view()
                            .clipsToBounds(true)
                            .with(\.layer.cornerRadius, 15)
                            .with(\.layer.cornerCurve, .continuous)
                            .with(\.layer.maskedCorners, maskedCorners)
                    }
                }
            }
            .background {
                Space()
                    .backgroundColor(.secondarySystemGroupedBackground)
                    .with(\.layer.cornerRadius, 15)
                    .with(\.layer.cornerCurve, .continuous)
            }
        }
        .size(width: .fill)
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
            Text(text)
                .font(.systemFont(ofSize: 16))
                .textColor(tintColor)
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
