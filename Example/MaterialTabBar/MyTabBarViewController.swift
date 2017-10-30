//
//  MyTabBarViewController.swift
//  MaterialTabBar_Example
//
//  Created by Michal Rentka on 26/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

import MaterialTabBar

class MyTabBarViewController: TabBarController {
    var style: TabBarStyle = .scrollable

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.style.title
        
        var items: [TabBarItem] = []
        switch self.style {
        case .scrollable:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "View Controller 2"),
                                      TabBarItem(title: "Ctrl 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "VC 5")])
        case .animatedType:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "Controller 2"),
                                      TabBarItem(title: "Controller 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "Controller 5")])
            self.tabBar?.type = UIDevice.current.orientation.isLandscape ? .normal : .scrollable
        case .normal:
            items.append(contentsOf: [TabBarItem(title: "First"),
                                      TabBarItem(title: "Second"),
                                      TabBarItem(title: "Third")])
            self.tabBar?.type = .normal
        case .line:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "View Controller 2"),
                                      TabBarItem(title: "Ctrl 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "VC 5")])
            self.tabBarPosition = .bottom
            self.tabBar?.selectionLinePosition = .top
            self.tabBar?.selectionLineHeight = 2
            self.tabBar?.selectionLineBackgroundColor = .red
        case .highlight:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "View Controller 2"),
                                      TabBarItem(title: "Ctrl 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "VC 5")])
            self.tabBar?.selectionType = .highlight
            self.tabBar?.buttonHighlightColor = UIColor.blue.withAlphaComponent(0.5)
            self.tabBar?.buttonSelectionColor = .blue
        case .highlightAndLine:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "View Controller 2"),
                                      TabBarItem(title: "Ctrl 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "VC 5")])
            self.tabBar?.selectionType = .highlightAndLine
            self.tabBar?.buttonTextColor = UIColor.gray.withAlphaComponent(0.5)
            self.tabBar?.buttonSelectionColor = .black
        case .headerView:
            items.append(contentsOf: [TabBarItem(title: "First"),
                                      TabBarItem(title: "Second"),
                                      TabBarItem(title: "Third")])
            let headerView = UIView()
            headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            headerView.backgroundColor = .blue
            self.headerView = headerView
        case .lineCustomisation:
            items.append(contentsOf: [TabBarItem(title: "Controller 1"),
                                      TabBarItem(title: "View Controller 2"),
                                      TabBarItem(title: "Ctrl 3"),
                                      TabBarItem(title: "Controller 4"),
                                      TabBarItem(title: "VC 5")])
            self.tabBar?.selectionLineStartsAtButtonInset = true
            self.tabBar?.selectionLineWidthMultiplier = 0.5
        }
        
        let controllers = items.map { ViewController(item: $0) }
        self.setViewControllers(controllers, animated: false)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if self.style == .animatedType {
            coordinator.animate(alongsideTransition: { _ in
                self.tabBar?.type = UIDevice.current.orientation.isLandscape ? .normal : .scrollable
            }, completion: nil)
        }
    }
}
