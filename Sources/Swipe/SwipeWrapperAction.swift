//
//  File.swift
//  
//
//  Created by y H on 2024/5/18.
//

import UIKit

@MainActor
final class SwipeActionWrapper: @unchecked Sendable {
    let action: any SwipeAction
    
    private(set) var rendered: Bool = false
    
    lazy var contentView: UIView = {
        rendered = true
        return action.makeCotnentView()
    }()
    
    lazy var backgroundView: UIView = {
        return action.makeBackgroundView()
    }()
    
    var swipeContentWrapperView: SwipeContentWrapperView? {
        guard rendered else { return nil }
        return sequence(first: contentView, next: { $0?.superview }).compactMap { $0 as? SwipeContentWrapperView }.first
    }
    
    init(action: any SwipeAction) {
        self.action = action
    }
}
