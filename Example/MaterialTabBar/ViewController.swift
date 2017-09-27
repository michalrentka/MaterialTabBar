//
//  ViewController.swift
//  MaterialTabBar_Example
//
//  Created by Michal Rentka on 26/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

import MaterialTabBar

class ViewController: UIViewController, TabBarChildController {
    var tabItem: TabBarItem
    
    init(item: TabBarItem) {
        self.tabItem = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .white

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = self.tabItem.title
        view.addSubview(label)

        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        self.view = view
    }
}
