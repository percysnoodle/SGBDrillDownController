SGBDrillDownController
======================

SGBDrillDownController is a parent view controller for the iPad which manages a stack of controllers similarly to UINavigationController while keeping the top two controllers visible similarly to UISplitViewController.

Installation
------------

To use SGBDrillDownController in your project, add this line to your podfile:

```ruby
pod 'SGBDrillDownController', '~> 1.1'
```

and then run: 

```sh
$ pod install
```

for more information about pods and podfiles, visit the [CocoaPods](http://cocoapods.org) website.

iOS 7 Support
-------------

The drill down controller implements iOS 7 style animations and swipe-to-navigate-back functionality to mimic UINavigationController. The animations are used on all apps compiled with the iOS7+ SDK. The swipe-to-navigate-back functionality is only available when the app is both compiled with the iOS7+ SDK and running on an iOS7+ device.

Swipe-to-navigate-back is only enabled if there are at least 2 view controllers on the `leftViewControllers` stack since popping operations on either the second-to-last or last view controller have different animations than the swipe-to-navigate-back functionality would imply visually.

Due to limitations in the UINavigationBar class, navigation items are not interactively animated during a swipe-to-navigate-back guesture unlike in UINavigationController.

Rotation, Swiping back, and Tab/Navigation Controllers
------------------------------------------------------

Unfortunately neither UITabBarController nor UINavigationController call the `shouldAutorotate` function on their child view controllers. If you embed the drill down controller in one of these controllers and support multiple device orientations, you'll notice visual glitching when you rotate the device while in the middle of swiping to navigate back. To fix this problem, you can implement a category on UINavigationController or UITabBarController to implement passing through the `shouldAutorotate` call to the current view controller similar to the following code:

    @implementation UITabBarController (SGBAutorotationFixes)

    - (BOOL)shouldAutorotate {
        return [self.selectedViewController shouldAutorotate];
    }

    - (NSUInteger)supportedInterfaceOrientations {
        return [self.selectedViewController supportedInterfaceOrientations];
    }

    @end
