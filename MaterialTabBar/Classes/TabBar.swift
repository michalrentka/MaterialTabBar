//
//  TabBar.swift
//  TabBarController
//
//  Created by Michal Rentka on 18/08/2017.
//  Copyright © 2017 Michal Rentka. All rights reserved.
//

import UIKit

typealias TabBarSelectionChangedAction = (_ index: Int) -> Void
private typealias ContentViews = (contentView: UIView, buttonWidths: [NSLayoutConstraint])

public protocol TabBarDelegate: class {
    func tabBarConfigureButton(_ button: UIButton, at index: Int)
}

public protocol TabBar: class {
    var tabBarDelegate: TabBarDelegate? { get set }
    var items: [TabBarItem] { get set }
    var type: TabBarType { get set }
    var selectionType: TabBarSelection { get set }
    var selectionLineHeight: CGFloat { get set }
    var selectionLineBackgroundColor: UIColor { get set }
    var selectionLinePosition: TabBarLinePosition { get set }
    var buttonFont: UIFont { get set }
    var buttonTextColor: UIColor { get set }
    var buttonSelectionColor: UIColor? { get set }
    var buttonHighlightColor: UIColor? { get set }
    var backgroundColor: UIColor? { get set }
}

/// Type which specifies the layout of tab bar.
/// - normal: Buttons have the same width and are fitted to screen width.
/// - scrollable: Buttons have as much width as they need and the tab bar is scrollable.
public enum TabBarType {
    case normal, scrollable
}

/// Type which specifies how selection of button is shown.
/// - highlight: Button is highlighted (isSelected is set to true for button).
/// - line: Line appears under the button.
/// - highlightAndLine: Both, button is highlighted and line appears under the button.
public enum TabBarSelection {
    case highlight, line, highlightAndLine
}

/// Position of the selection line in the tab bar.
public enum TabBarLinePosition {
    case top, bottom
}

/// Item which is shown in the tab bar as a button. Title and image can be specified for the button.
public struct TabBarItem {
    public let title: String?
    public let image: UIImage?
    public let highlightImage: UIImage?
    public let selectionImage: UIImage?
    
    public init(title: String) {
        self.title = title
        self.image = nil
        self.highlightImage = nil
        self.selectionImage = nil
    }
    
    public init(image: UIImage, highlightImage: UIImage? = nil, selectionImage: UIImage? = nil) {
        self.title = nil
        self.image = image
        self.highlightImage = highlightImage
        self.selectionImage = selectionImage
    }
    
    public init(title: String, image: UIImage, highlightImage: UIImage? = nil, selectionImage: UIImage? = nil) {
        self.title = title
        self.image = image
        self.highlightImage = highlightImage
        self.selectionImage = selectionImage
    }
}

extension TabBarItem: Equatable {
    public static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
        return lhs.title == rhs.title &&
               lhs.image == rhs.image &&
               lhs.selectionImage == rhs.selectionImage
    }
}

final class TabBarView: UIScrollView, TabBar {
    private static let height: CGFloat = 44.0
    private static let defaultButtonInsets = UIEdgeInsets(top: 8.0, left: 20.0, bottom: 8.0, right: 20.0)
    private var selectedIndex: Int = 0
    /// Internal block called when selection in TabBarView changes so that the parent
    /// controller can change content as needed.
    var selectionChanged: TabBarSelectionChangedAction?
    /// contentOffset.x of the scroll view when scrolling starts,
    /// it's used to calculate contentOffset when selecting items.
    private var scrollXBeforeChange: CGFloat?

    // MARK: -  Views

    /// A container view which holds all visible buttons.
    private weak var contentView: UIView? {
        willSet {
            if let view = self.contentView {
                view.removeFromSuperview()
            }
        }
        
        didSet {
            if let view = self.contentView {
                self.insertSubview(view, at: 0)
                self.contentViewWidthConstraint = self.createConstraints(for: view)
                self.contentViewWidthConstraint?.isActive = self.type == .normal
                self.layoutIfNeeded()
            }
        }
    }
    /// The line that appears under selected button, shown for TabBarSelection.line or .highlightAndLine
    private weak var selectionLine: UIView?
    /// All visible buttons, used for configuring font, color, etc.
    private var buttons: [UIButton] {
        guard let contentView = self.contentView else { return [] }
        return contentView.subviews.flatMap { $0 as? UIButton }
    }

    // MARK: -  Constraints

    private var contentViewWidthConstraint: NSLayoutConstraint?
    private var buttonWidthConstraints: [NSLayoutConstraint] = []
    private var lineWidth: NSLayoutConstraint?
    private var lineLeft: NSLayoutConstraint?
    private var lineHeight: NSLayoutConstraint?
    private var lineTop: NSLayoutConstraint?
    private var lineBottom: NSLayoutConstraint?

    // MARK: - TabBar

    weak var tabBarDelegate: TabBarDelegate?
    var items: [TabBarItem] = [] {
        didSet {
            self.selectedIndex = 0
            let data = self.createContentViews(from: self.items,
                                               font: self.buttonFont,
                                               textColor: self.buttonTextColor,
                                               highlightColor: self.buttonHighlightColor,
                                               selectionColor: self.buttonSelectionColor,
                                               with: self.type, delegate: self.tabBarDelegate)
            self.contentView = data.contentView
            self.buttonWidthConstraints = data.buttonWidths
            self.selectButton(at: self.selectedIndex)
        }
    }
    var type: TabBarType = .normal {
        didSet {
            let isNormal = self.type == .normal
            self.contentViewWidthConstraint?.isActive = isNormal
            self.buttonWidthConstraints.forEach { $0.isActive = isNormal }
            self.layoutIfNeeded()
            self.resetLineAndScrollPosition()
        }
    }
    var selectionType: TabBarSelection = .highlight {
        willSet {
            switch self.selectionType {
            case .highlight:
                self.removeHighlight(at: self.selectedIndex)
            case .line:
                self.selectionLine?.isHidden = true
            case .highlightAndLine: break
            }
        }
        
        didSet {
            switch self.selectionType {
            case .highlight: break
            case .line, .highlightAndLine:
                self.selectionLine?.isHidden = false
            }
            self.selectButton(at: self.selectedIndex)
        }
    }
    var selectionLineHeight: CGFloat = 4.0 {
        didSet {
            self.lineHeight?.constant = self.selectionLineHeight
            self.selectionLine?.layoutIfNeeded()
        }
    }
    var selectionLineBackgroundColor: UIColor = .black {
        didSet {
            self.selectionLine?.backgroundColor = self.selectionLineBackgroundColor
        }
    }
    var selectionLinePosition: TabBarLinePosition = .bottom {
        didSet {
            self.lineTop?.isActive = self.selectionLinePosition == .top
            self.lineBottom?.isActive = self.selectionLinePosition == .bottom
            self.selectionLine?.layoutIfNeeded()
        }
    }
    var buttonFont: UIFont = .systemFont(ofSize: 14.0) {
        didSet {
            self.buttons.forEach { $0.titleLabel?.font = self.buttonFont }
        }
    }
    var buttonTextColor: UIColor = .black {
        didSet {
            self.buttons.forEach { $0.setTitleColor(self.buttonTextColor, for: .normal) }
        }
    }
    var buttonSelectionColor: UIColor? {
        didSet {
            self.buttons.forEach { $0.setTitleColor(self.buttonSelectionColor, for: .selected) }
        }
    }
    var buttonHighlightColor: UIColor? {
        didSet {
            self.buttons.forEach { $0.setTitleColor(self.buttonSelectionColor, for: .highlighted) }
        }
    }

    // MARK: - Initializers

    init(type: TabBarType, selectionType: TabBarSelection) {
        self.type = type
        self.selectionType = selectionType
        super.init(frame: .zero)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    // MARK: - Actions
    
    func resetLineAndScrollPosition() {
        guard let button = self.button(at: self.selectedIndex) else { return }
        
        if self.selectionType == .line || self.selectionType == .highlightAndLine {
            self.lineLeft?.constant = round(button.frame.minX)
            self.lineWidth?.constant = round(button.frame.width)
            self.selectionLine?.layoutIfNeeded()
        }

        let newScrollOffsetX = self.scrollXPositionForButton(atX: button.frame.minX, width: button.frame.width,
                                                             contentX: self.contentOffset.x, contentWidth: self.bounds.width)
        self.contentOffset = CGPoint(x: newScrollOffsetX, y: self.contentOffset.y)
    }
    
    @objc private func buttonTapped(_ button: UIButton) {
        let index = button.tag
        guard index < self.items.count else {
            return
        }

        self.selectedIndex = index
        self.selectionChanged?(index)
    }
    
    private func selectButton(at index: Int) {
        self.selectButton(at: index, previous: 0, progress: 1.0)
    }

    private func selectButton(at index: Int, previous previousIndex: Int, progress: CGFloat) {
        switch self.selectionType {
        case .highlight:
            self.highlightButton(at: index, previous: previousIndex, progress: progress)
        case .line:
            self.moveLine(to: index, previous: previousIndex, progress: progress)
        case .highlightAndLine:
            self.highlightButton(at: index, previous: previousIndex, progress: progress)
            self.moveLine(to: index, previous: previousIndex, progress: progress)
        }
        if let initialScrollPosition = self.scrollXBeforeChange {
            self.scrollToButtonIfNeeded(from: initialScrollPosition, to: index, progress: progress)
        }
    }
    
    private func moveLine(to index: Int, previous previousIndex: Int, progress: CGFloat) {
        guard previousIndex < self.buttons.count && index < self.buttons.count &&
              previousIndex >= 0 && index >= 0 else {
            return
        }
        
        let oldButton = self.buttons[previousIndex]
        let newButton = self.buttons[index]

        let x = oldButton.frame.minX + ((newButton.frame.minX - oldButton.frame.minX) * progress)
        let width = oldButton.frame.width + ((newButton.frame.width - oldButton.frame.width) * progress)

        self.lineLeft?.constant = round(x)
        self.lineWidth?.constant = round(width)
        self.layoutIfNeeded()
    }
    
    private func scrollToButtonIfNeeded(from previousXOffset: CGFloat, to index: Int, progress: CGFloat) {
        guard self.type == .scrollable, let button = self.button(at: index) else { return }
        let newScrollOffsetX = self.scrollXPositionForButton(atX: button.frame.minX, width: button.frame.width,
                                                             contentX: previousXOffset, contentWidth: self.bounds.width)
        self.scrollToButton(from: previousXOffset, to: newScrollOffsetX, progress: progress)
    }
    
    private func scrollToButton(from previousX: CGFloat, to newX: CGFloat, progress: CGFloat) {
        let x = previousX + ((newX - previousX) * progress)
        self.contentOffset = CGPoint(x: round(x), y: self.contentOffset.y)
    }
    
    private func scrollXPositionForButton(atX lineX: CGFloat, width lineWidth: CGFloat,
                                          contentX: CGFloat, contentWidth: CGFloat) -> CGFloat {
        if lineX < contentX {
            return lineX
        }
        let contentRight = contentX + contentWidth
        let lineRight = lineX + lineWidth
        if lineRight > contentRight {
            return contentX + (lineRight - contentRight)
        }
        return contentX
    }

    private func highlightButton(at index: Int, previous previousIndex: Int, progress: CGFloat) {
        if let button = self.button(at: previousIndex) {
            button.isSelected = progress <= 0.5
        }
        if let button = self.button(at: index) {
            button.isSelected = progress > 0.5
        }
    }

    private func removeHighlight(at index: Int) {
        if let button = self.button(at: index) {
            button.isHighlighted = false
            button.isSelected = false
        }
    }
    
    private func button(at index: Int) -> UIButton? {
        guard index >= 0 && index < self.buttons.count else {
            return nil
        }
        return self.buttons[index]
    }
    
    // MARK: - Autolayout
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: TabBarView.height)
    }
    
    // MARK: - View creation
    
    private func createContentViews(from items: [TabBarItem], font: UIFont, textColor: UIColor,
                                    highlightColor: UIColor?, selectionColor: UIColor?,
                                    with type: TabBarType, delegate: TabBarDelegate?) -> ContentViews {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        // Generate buttons for each item
        items.enumerated().forEach { data in
            let button = self.createButton(from: data.element,
                                           font: font,
                                           textColor: textColor,
                                           highlightColor: highlightColor,
                                           selectionColor: selectionColor,
                                           index: data.offset)
            delegate?.tabBarConfigureButton(button, at: data.offset)
            view.addSubview(button)
        }

        // Create appropriate constraints
        for i in stride(from: 0, to: items.count, by: 1) {
            let button = view.subviews[i]
            button.translatesAutoresizingMaskIntoConstraints = false
            button.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

            // Create right constraint to superview on last button
            if i == (items.count - 1) {
                button.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
                break
            }
            
            // Create left constraint to superview on first button
            if i == 0 {
                button.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            }
            
            // Create right constraint to following button on current button
            let nextButton = view.subviews[i + 1]
            button.rightAnchor.constraint(equalTo: nextButton.leftAnchor).isActive = true
        }
        
        var buttonWidths: [NSLayoutConstraint] = []

        if items.count > 1 {
            let firstButton = view.subviews[0]
            let isActive = type == .normal
            for i in stride(from: 1, to: items.count, by: 1) {
                let button = view.subviews[i]
                let constraint = button.widthAnchor.constraint(equalTo: firstButton.widthAnchor)
                constraint.isActive = isActive
                buttonWidths.append(constraint)
            }
        }

        return (view, buttonWidths)
    }
    
    private func createButton(from item: TabBarItem, font: UIFont, textColor: UIColor,
                              highlightColor: UIColor?, selectionColor: UIColor?, index: Int) -> UIButton {
        let button = UIButton()
        let selector = #selector(TabBarView.buttonTapped(_:))
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.tag = index
        button.titleLabel?.font = font
        button.contentEdgeInsets = TabBarView.defaultButtonInsets
        button.setTitle(item.title, for: .normal)
        button.setImage(item.image, for: .normal)
        button.setImage(item.highlightImage, for: .highlighted)
        button.setImage(item.selectionImage, for: .selected)
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(highlightColor, for: .highlighted)
        button.setTitleColor(selectionColor, for: .selected)
        return button
    }
    
    private func createConstraints(for contentView: UIView) -> NSLayoutConstraint {
        contentView.topAnchor.constraint(equalTo:self.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo:self.bottomAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo:self.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo:self.rightAnchor).isActive = true
        contentView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        return contentView.widthAnchor.constraint(equalTo: self.widthAnchor)
    }

    // MARK: - Setups

    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.showsHorizontalScrollIndicator = false
        self.setupSelectionLine()
    }
    
    private func setupSelectionLine() {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = self.selectionLineBackgroundColor
        line.isHidden = self.selectionType == .highlight
        self.addSubview(line)
        self.selectionLine = line

        self.lineTop = line.topAnchor.constraint(equalTo: self.topAnchor)
        self.lineTop?.isActive = self.selectionLinePosition == .top
        self.lineBottom = line.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        self.lineBottom?.isActive = self.selectionLinePosition == .bottom
        self.lineLeft = line.leftAnchor.constraint(equalTo: self.leftAnchor)
        self.lineLeft?.isActive = true
        self.lineWidth = line.widthAnchor.constraint(equalToConstant: 0.0)
        self.lineWidth?.isActive = true
        self.lineHeight = line.heightAnchor.constraint(equalToConstant: self.selectionLineHeight)
        self.lineHeight?.isActive = true
    }
}

extension TabBarView {
    func willChangeParentContent() {
        self.scrollXBeforeChange = self.contentOffset.x
    }
    
    func didChangeParentContent(to index: Int) {
        if index < self.items.count {
            self.selectedIndex = index
        }
        self.scrollXBeforeChange = nil
    }
    
    /// Called by parent controller when content changes
    /// - parameter oldIndex: Index of previous controller
    /// - parameter newIndex: Index of next controller
    /// - progress: Progress of change
    func observeParentContentChange(from oldIndex: Int, to newIndex: Int, progress: CGFloat) {
        self.selectButton(at: newIndex, previous: oldIndex, progress: progress)
    }
}
