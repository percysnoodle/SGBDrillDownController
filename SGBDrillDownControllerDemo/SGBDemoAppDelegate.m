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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self resetWindow];
    
#ifdef RUN_KIF_TESTS
    [[SGBDemoTestController sharedInstance] startTestingWithCompletionBlock:^{
        exit([[SGBDemoTestController sharedInstance] failureCount]);
    }];
#endif
    
    return YES;
}

- (void)resetWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    NSMutableArray *drillDownControllers = [NSMutableArray arrayWithCapacity:3];
    for (int i = 0; i < 3; i++)
    {
        SGBDrillDownController *drillDownController = [[SGBDrillDownController alloc] init];
        [drillDownControllers addObject:drillDownController];
        
        SGBDemoController *leftPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
        drillDownController.leftPlaceholderController = leftPlaceholderController;
        
        SGBDemoController *rightPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
        drillDownController.rightPlaceholderController = rightPlaceholderController;
    }
    
    SGBDemoTabBarController *tabBarController = [[SGBDemoTabBarController alloc] init];
    tabBarController.viewControllers = drillDownControllers;
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
}

@end
