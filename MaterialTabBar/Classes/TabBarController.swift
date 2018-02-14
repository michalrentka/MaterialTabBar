//
//  TabBarController.swift
//  TabBarController
//
//  Created by Michal Rentka on 18/08/2017.
//  Copyright © 2017 Michal Rentka. All rights reserved.
//

import UIKit

/// Position for the tab bar in controller.
/// - top: Tab bar on top.
/// - bottom: Tab bar on bottom.
public enum TabBarPosition {
    case top, bottom
}

/// Protocol for child controllers. Each child controller needs to specify a tabItem
/// so that the tab bar shows correct button for each child controller.
public protocol TabBarChildController: class {
    var tabItem: TabBarItem { get }
}

open class TabBarController: UIViewController {
    /// Page index before scroll used to calculate correct index of page to which we are scrolling.
    private var beforeScrollIndex: Int?
    /// Used to calculate correct index to which we are scrolling during scroll.
    private var scrollIndexDifference: Int?
    
    // MARK: -  Settings
    
    public weak var tabBar: TabBar? {
        return self.tabBarView
    }
    public var scrollView: UIScrollView? {
        return self.pageController.scrollView
    }
    public var headerView: UIView? {
        didSet {
            guard let containerView = self.headerViewContainer else { return }
            oldValue?.removeFromSuperview()
            self.headerViewHeightConstraint?.isActive = self.headerView == nil
            if let headerView = self.headerView {
                self.addHeaderView(headerView, to: containerView)
            }
            self.view.layoutIfNeeded()
        }
    }
    public private(set) var viewControllers: [UIViewController] = []
    public var tabBarPosition: TabBarPosition = .top {
        didSet {
            if oldValue != self.tabBarPosition {
                self.setupLayout(for: self.tabBarPosition)
                self.view.layoutIfNeeded()
            }
        }
    }
    public var selectedIndex: Int {
        get {
            let controller = self.pageController.viewControllers?.first
            return controller.flatMap { self.viewControllers.index(of: $0) } ?? 0
        }

        set {
            self.showViewController(at: newValue, oldIndex: self.selectedIndex)
        }
    }
    public var selectionChanged: TabBarSelectionChangedAction?
    private weak var tabBarView: TabBarView?
    private weak var pageController: UIPageViewController!
    private weak var headerViewContainer: UIView?
    private var transitioningController: UIViewController?
    
    // MARK: - Constraints
    
    private var tabBarTopConstraint: NSLayoutConstraint?
    private var tabBarBottomConstraint: NSLayoutConstraint?
    private var headerViewTopConstraint: NSLayoutConstraint?
    private var headerViewBottomConstraint: NSLayoutConstraint?
    private var headerViewHeightConstraint: NSLayoutConstraint?
    private var contentViewTopConstraint: NSLayoutConstraint?
    private var contentViewBottomConstraint: NSLayoutConstraint?
    private var tabBarTopContentViewBottomConstraint: NSLayoutConstraint?
    private var tabBarBottomContentViewTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setupHeaderViewContainer()
        self.setupTabBar()
        self.setupPageViewController()
        self.setupAdditionalConstraints()
        self.setupLayout(for: self.tabBarPosition)
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.tabBarView?.resetLineAndScrollPosition()
        }, completion: nil)
    }
    
    // MARK: - Actions
    
    public func setViewControllers(_ controllers: [UIViewController & TabBarChildController], animated: Bool) {
        self.viewControllers = controllers
        self.tabBarView?.items = controllers.map { $0.tabItem }
        if let controller = controllers.first {
            self.pageController.setViewControllers([controller], direction: .forward,
                                                   animated: animated, completion: nil)
        }
    }
    
    private func showViewController(at index: Int, oldIndex: Int? = nil, animated: Bool = true) {
        guard index != oldIndex && index >= 0 && index < self.viewControllers.count else {
            return
        }
        var direction: UIPageViewControllerNavigationDirection = .forward
        if let oldIndex = oldIndex, index < oldIndex {
            direction = .reverse
        }
        self.willChangeContent(to: index)
        self.pageController.setViewControllers([self.viewControllers[index]], direction: direction,
                                               animated: animated, completion: { [weak self] completed in
            if completed {
                self?.selectionChanged?(index)
            }
        })
    }
    
    private func willChangeContent(to index: Int? = nil) {
        let currentIndex = self.selectedIndex
        self.beforeScrollIndex = currentIndex
        self.scrollIndexDifference = index.map { $0 - currentIndex }
        self.tabBarView?.willChangeParentContent()
    }
    
    private func didChangeContent() {
        self.beforeScrollIndex = nil
        self.scrollIndexDifference = nil
        self.tabBarView?.didChangeParentContent(to: self.selectedIndex)
    }
    
    private func addHeaderView(_ headerView: UIView, to containerView: UIView) {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)
        headerView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        headerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        headerView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        headerView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
    }

    // MARK: - Setups
    
    private func setupLayout(for tabBarPosition: TabBarPosition) {
        let isTabBarOnTop = tabBarPosition == .top
        self.tabBarTopConstraint?.isActive = isTabBarOnTop
        self.tabBarBottomConstraint?.isActive = !isTabBarOnTop
        self.headerViewTopConstraint?.isActive = isTabBarOnTop
        self.headerViewBottomConstraint?.isActive = !isTabBarOnTop
        self.tabBarTopContentViewBottomConstraint?.isActive = !isTabBarOnTop
        self.tabBarBottomContentViewTopConstraint?.isActive = isTabBarOnTop
        self.contentViewTopConstraint?.isActive = !isTabBarOnTop
        self.contentViewBottomConstraint?.isActive = isTabBarOnTop
    }
    
    /// Creates a tabbar, which is added as subview and sets needed constraints
    private func setupTabBar() {
        let tabBar = TabBarView(type: .scrollable, selectionType: .line)
        tabBar.selectionChanged = { [weak self] index in
            self?.showViewController(at: index, oldIndex: self?.selectedIndex)
        }
        self.view.addSubview(tabBar)
        self.tabBarView = tabBar

        self.tabBarView?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tabBarView?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    private func setupPageViewController() {
        let controller = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        controller.dataSource = self
        controller.delegate = self
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.scrollView?.delegate = self

        controller.willMove(toParentViewController: self)
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        controller.didMove(toParentViewController: self)
        self.pageController = controller

        let layoutGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            layoutGuide = self.view.safeAreaLayoutGuide
        } else {
            layoutGuide = self.view.layoutMarginsGuide
        }

        self.pageController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.pageController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.contentViewTopConstraint = self.pageController.view.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        self.contentViewBottomConstraint = self.pageController.view.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
    }
    
    private func setupHeaderViewContainer() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        self.view.addSubview(containerView)
        self.headerViewContainer = containerView
        
        let layoutGuide: UILayoutGuide
        if #available(iOS 11.0, *) {
            layoutGuide = self.view.safeAreaLayoutGuide
        } else {
            layoutGuide = self.view.layoutMarginsGuide
        }
        
        self.headerViewContainer?.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.headerViewContainer?.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.headerViewTopConstraint = self.headerViewContainer?.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        self.headerViewBottomConstraint = self.headerViewContainer?.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        self.headerViewHeightConstraint = self.headerViewContainer?.heightAnchor.constraint(equalToConstant: 0.0)
        self.headerViewHeightConstraint?.isActive = self.headerView == nil
        
        if let headerView = self.headerView {
            self.addHeaderView(headerView, to: containerView)
        }
    }
    
    private func setupAdditionalConstraints() {
        let contentView = self.pageController.view!
        let headerView = self.headerViewContainer!
        
        self.tabBarTopConstraint = self.tabBarView?.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        self.tabBarBottomConstraint = self.tabBarView?.bottomAnchor.constraint(equalTo: headerView.topAnchor)
        self.tabBarBottomContentViewTopConstraint = self.tabBarView?.bottomAnchor.constraint(equalTo: contentView.topAnchor)
        self.tabBarTopContentViewBottomConstraint = self.tabBarView?.topAnchor.constraint(equalTo: contentView.bottomAnchor)
    }
}

extension TabBarController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.viewControllers.index(of: viewController), (index + 1) < self.viewControllers.count else {
            return nil
        }
        return self.viewControllers[index + 1]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                                   viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.viewControllers.index(of: viewController), (index - 1) >= 0 else {
            return nil
        }
        return self.viewControllers[index - 1]
    }
}

extension TabBarController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        self.transitioningController = pendingViewControllers.last
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let viewController = self.transitioningController,
              let index = self.viewControllers.index(of: viewController) else {
            return
        }
        self.selectionChanged?(index)
    }
}

extension TabBarController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let initialIndex = self.beforeScrollIndex else { return }
        // In UIPageViewController the progress range is always <0.0; 2.0>, where 1.0 is the current (middle) page
        let scrollProgress = scrollView.contentOffset.x / scrollView.frame.width
        let progress: CGFloat
        let index: Int
        if scrollProgress == 1.0 {
            index = self.selectedIndex
            progress = scrollProgress
        } else {
            let difference = self.scrollIndexDifference ?? (scrollProgress > 1.0 ? 1 : -1)
            index = initialIndex + difference
            progress = abs(1.0 - scrollProgress)
        }
        self.tabBarView?.observeParentContentChange(from: initialIndex, to: index, progress: progress)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.willChangeContent()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.didChangeContent()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didChangeContent()
    }
}

private extension UIPageViewController {
    var scrollView: UIScrollView? {
        for view in self.view.subviews {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
        }
        return nil
    }
}
