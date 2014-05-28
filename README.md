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

Testing
-------

SGBDrillDownController uses KIF to run a series of functional tests in the demo project. To run the tests

- Install KIF by running `pod install`
- Opening `SGBDrillDownControllerDemo.xcworkspace` (_not_ `SGBDrillDownControllerDemo.xcodeproj`)
- Choose the `Funtional Tests` target
- Build and Run

Note: Xcode (via LLVM) has added a compiler warning for "Unintentional Root Class" (LLVM's `-Wobj-root-class`) that KIF triggers with its `LoadableCategory.h` hack. Since CocoaPods enables all warnings to the highest level, this warning is treated as an error, and you will not be able to build or run the tests until you adjust the settings. To change this settting, select the *Pods* project, navigate to the *Build Settings* for the *Pods-KIF* (not just *Pods*) target, and select *No* for *Unintentional Root Class* under the section *Apple LLVM 5.0 - Warnings - Objective C*. Unfortunately every time you run `pod install` this setting will be reset and you will need to follow these steps again.

iOS State Preservation and Restoration
--------------------------------------

The drill down controller implements full state preservation and restoration in iOS6+. All child view controllers with a non-empty `restorationIdentifier` property will be preserved and restored.

Note: the drill down controller will do it's best to maintain as much state as possible. This results in the following caveats:

- If, for example, five controllers are on the stack only the last three have a valid restoration identifier, the first two will not be restored but the last three will be restored.
- Similarly, the drill down controller will attempt to maintain the state of which child controller is presented on the right/left, but if none of the left view controllers have valid restoration identifiers and the right view controller does, then the right view controller will be restored as the only element on the left view controller stack to maintain valid internal state of the drill down controller.

It is your responsiblity to ensure that restoration identifiers are applied properly to maintain a valid state when your app is restored.

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

Unexpected Behavior
-------------------

Due to bugs introduced by Apple in iOS 7.1 in UINavigationBar, the drill down controller manages the `hidesBackButton` property on the `navigationItem` properties of the view controllers it contains. It seems unlikely that this will cause any issues as it maintains the general expectations of how the navigation bars will look, but if you encounter issues in a specific use case, at least you know why the behavior exists.
