# MaterialTabBar

[![Version](https://img.shields.io/cocoapods/v/MaterialTabBar.svg?style=flat)](http://cocoapods.org/pods/MaterialTabBar)
[![License](https://img.shields.io/cocoapods/l/MaterialTabBar.svg?style=flat)](http://cocoapods.org/pods/MaterialTabBar)
[![Platform](https://img.shields.io/cocoapods/p/MaterialTabBar.svg?style=flat)](http://cocoapods.org/pods/MaterialTabBar)

## MaterialTabBar

A simple and customizable tab bar controller which imitates the Material design. You can customize the position of the tab bar, selection type, content of each tab, colors, fonts, etc. Changes to the tab bar can also be animated with `UIKit`.

## Usage

Import MaterialTabBar at the top of the Swift file of your custom tab bar controller and all child controllers. Subclass the `TabBarController` and set child view controllers in `viewDidLoad` method.

```
import MaterialTabBar

class MyTabBarController: TabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let childControllers = [...]
        self.setViewControllers(childControllers, animated: false)
    }
}
```

Each child controller needs to implement the `TabBarChildController` protocol which makes the `tabItem` available. In the `tabItem` you can specify the content that is shown in tab for this controller.

```
import MaterialTabBar

class MyChildViewController: UIViewController, TabBarChildController {
    var tabItem: TabBarItem
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. In the example project you can see how the `MaterialTabBar` can be used.

## Installation

MaterialTabBar is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MaterialTabBar'
```

## Author

Michal Rentka, michalrentka@gmail.com

## License

MaterialTabBar is available under the MIT license. See the LICENSE file for more info.
