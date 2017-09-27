//
//  PickerViewController.swift
//  MaterialTabBar
//
//  Created by Michal Rentka on 09/26/2017.
//  Copyright (c) 2017 Michal Rentka. All rights reserved.
//

import UIKit

enum TabBarStyle {
    case scrollable, normal, highlight, line, highlightAndLine, animatedType
    
    var title: String {
        switch self {
        case .scrollable:
            return "Scrollable tab bar"
        case .normal:
            return "Normal tab bar"
        case .highlight:
            return "Customized highlight selection"
        case .line:
            return "Customized line selection"
        case .highlightAndLine:
            return "Customized highlight and line selection"
        case .animatedType:
            return "Tabbar type changed on orientation change"
        }
    }
}

class PickerViewController: UIViewController {
    private let cellId = "PickerCell"
    private let styles: [TabBarStyle] = [.scrollable, .normal, .highlight, .line,
                                         .highlightAndLine, .animatedType]
    
    @IBOutlet private weak var tableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MaterialTabBar"
        self.setupTableView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTabBar", let style = sender as? TabBarStyle,
           let controller = segue.destination as? MyTabBarViewController {
            controller.style = style
        }
    }
    
    private func showTabBarController(with style: TabBarStyle) {
        self.performSegue(withIdentifier: "showTabBar", sender: style)
    }
    
    private func setupTableView() {
        self.tableView?.register(UITableViewCell.self, forCellReuseIdentifier: self.cellId)
    }
}

extension PickerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let style = self.styles[indexPath.row]
        cell.textLabel?.text = style.title
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showTabBarController(with: self.styles[indexPath.row])
    }
}

