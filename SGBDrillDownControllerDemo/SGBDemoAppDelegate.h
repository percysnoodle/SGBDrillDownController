//
//  SGBAppDelegate.h
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGBDemoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)createWindow;
- (UITabBarController *)createTabBarControllerAndSetAsRootViewController;
- (void)createDrillDownControllersAndAddToTabBarController;

@end
