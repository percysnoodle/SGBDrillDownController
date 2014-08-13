//
//  SGBAppDelegate.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDemoAppDelegate.h"
#import "SGBDrillDownController.h"
#import "SGBDemoController.h"
#import "SGBDemoTabBarController.h"

#ifdef RUN_KIF_TESTS
#import "SGBDemoTestController.h"
#endif

@interface SGBDemoAppDelegate ()

@end

@implementation SGBDemoAppDelegate

static NSString * const kSGBStateRestorationRootViewControllerKey = @"rootViewController";
static NSString * const kSGBStateRestorationDrillDownControllerTabPrefixKey = @"tabBarController-drillDownController";

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self createWindow];
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    if ([[identifierComponents firstObject] isEqualToString:kSGBStateRestorationRootViewControllerKey])
    {
        if (identifierComponents.count == 1)
        {
            UITabBarController *tabBarController = [self createTabBarControllerAndSetAsRootViewController];
            return tabBarController;
        }
        else if (identifierComponents.count == 2 && [[identifierComponents lastObject] hasPrefix:kSGBStateRestorationDrillDownControllerTabPrefixKey])
        {
            UIViewController *viewController = [SGBDrillDownController viewControllerWithRestorationIdentifierPath:identifierComponents coder:coder];
            NSAssert(viewController, @"Expected viewControllerWithRestorationIdentifierPath to return controller instance.");
            UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
            NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:tabBarController.viewControllers];
            if (viewController)
            {
                [viewControllers addObject:viewController];
                viewController.restorationClass = nil;
                tabBarController.viewControllers = viewControllers;
            }
            return viewController;
        }
        else
        {
            return nil;
        }
    }
    return nil;
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder
{
    // Make the tab bar update its items.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
   tabBarController.viewControllers = [tabBarController.viewControllers copy];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (!self.window)
    {
        [self createWindow];
    }

    if (!self.window.rootViewController)
    {
        [self createTabBarControllerAndSetAsRootViewController];
        [self createDrillDownControllersAndAddToTabBarController];
    }

    [self.window makeKeyAndVisible];

#ifdef RUN_KIF_TESTS
    [[SGBDemoTestController sharedInstance] startTestingWithCompletionBlock:^{
        exit([[SGBDemoTestController sharedInstance] failureCount]);
    }];
#endif
    
    return YES;
}

#ifndef RUN_KIF_TESTS
- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
  return YES;
}
#endif

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder
{

}

- (void)createWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.restorationIdentifier = NSStringFromClass([self.window class]);
    self.window.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
}

- (UITabBarController *)createTabBarControllerAndSetAsRootViewController
{
    SGBDemoTabBarController *tabBarController = [[SGBDemoTabBarController alloc] init];
    tabBarController.restorationIdentifier = kSGBStateRestorationRootViewControllerKey;
    self.window.rootViewController = tabBarController;
    return tabBarController;
}

- (void)createDrillDownControllersAndAddToTabBarController
{
    NSMutableArray *drillDownControllers = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < 3; i++)
    {
        SGBDrillDownController *drillDownController = [[SGBDrillDownController alloc] init];
        drillDownController.restorationIdentifier = [NSString stringWithFormat:@"%@-%i", kSGBStateRestorationDrillDownControllerTabPrefixKey, i];
        drillDownController.restorationClass = nil;

        SGBDemoController *leftPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
        leftPlaceholderController.restorationIdentifier = @"leftPlaceholderController";
        drillDownController.leftPlaceholderController = leftPlaceholderController;

        SGBDemoController *rightPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
        rightPlaceholderController.restorationIdentifier = @"rightPlaceholderController";
        drillDownController.rightPlaceholderController = rightPlaceholderController;
        
        if (i == 2)
        {
            drillDownController.title = @"Embedded";
            drillDownController.propagatesNavigationItem = NO;
            drillDownController.navigationBarPosition = UIBarPositionTop;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:drillDownController];
            [drillDownControllers addObject:navigationController];
        }
        else
        {
            [drillDownControllers addObject:drillDownController];
        }
    }

    NSAssert([self.window.rootViewController isKindOfClass:[UITabBarController class]], @"Expected root view controller to be instance of UITabBarController");
    UITabBarController *tabBarController = (UITabBarController*)self.window.rootViewController;
    tabBarController.viewControllers = drillDownControllers;
}

@end
