//
//  ViewController.swift
//  SwipeExapmple
//
//  Created by y H on 2024/5/11.
//

import UIKit
import Swipe
import UIComponent
import UIComponentSwipe

class ViewController: UIViewController {
    
    let componentView = ComponentScrollView()
    
    var component: any Component {
        VStack {
            Group(title: "Test") {
                Cell(title: "For 1")
                    .swipeActions {
                        SwipeActionComponent(identifier: "Add", 
                                             horizontalEdge: .right,
                                             backgroundColor: .systemGreen,
                                             body: {
                            SwipeActionContent(image: UIImage.add, text: "Add", alignment: .ttb, tintColor: .white)
                        },
                                             alert: nil,
                                             actionHandler: { completion, action, form in
                            completion(.close)
                        })
                        SwipeActionComponent(identifier: "Remove",
                                             horizontalEdge: .right,
                                             backgroundColor: .systemRed,
                                             body: {
                            SwipeActionContent(image: UIImage.remove, text: "Remove", alignment: .ltr, tintColor: .white)
                        },
                                             alert: nil,
                                             actionHandler: { completion, action, form in
                            completion(.swipeFull(nil))
                        })
                    }
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(componentView)
        componentView.backgroundColor = .systemGroupedBackground
        reloadComponent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func reloadComponent() {
        componentView.component = component
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        componentView.frame = view.bounds
    }
}
