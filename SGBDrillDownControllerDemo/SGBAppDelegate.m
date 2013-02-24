//
//  SGBAppDelegate.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBAppDelegate.h"
#import "SGBDrillDownController.h"
#import "SGBDemoController.h"

@implementation SGBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    SGBDrillDownController *drillDownController = [[SGBDrillDownController alloc] init];
    self.window.rootViewController = drillDownController;
    [self.window makeKeyAndVisible];
    
    [drillDownController pushViewController:[[SGBDemoController alloc] initWithNumber:1] animated:NO completion:nil];
    
    return YES;
}

@end
