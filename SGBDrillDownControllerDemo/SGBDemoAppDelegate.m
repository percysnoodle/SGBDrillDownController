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

#ifdef RUN_KIF_TESTS
#import "SGBDemoTestController.h"
#endif

@interface SGBDemoAppDelegate ()

@property (nonatomic, strong) SGBDrillDownController *drillDownController;

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
    
    self.drillDownController = [[SGBDrillDownController alloc] init];
    self.window.rootViewController = self.drillDownController;
    [self.window makeKeyAndVisible];
    
    SGBDemoController *leftPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
    self.drillDownController.leftPlaceholderController = leftPlaceholderController;
    
    SGBDemoController *rightPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
    self.drillDownController.rightPlaceholderController = rightPlaceholderController;
}

@end
