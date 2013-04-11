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

@interface SGBAppDelegate () <SGBDemoControllerDelegate>

@property (nonatomic, strong) SGBDrillDownController *drillDownController;

@end

@implementation SGBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    self.drillDownController = [[SGBDrillDownController alloc] init];
    self.window.rootViewController = self.drillDownController;
    [self.window makeKeyAndVisible];
    
    SGBDemoController *leftPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
    leftPlaceholderController.delegate = self;
    self.drillDownController.leftPlaceholderController = leftPlaceholderController;
    
    SGBDemoController *rightPlaceholderController = [[SGBDemoController alloc] initWithNumber:0];
    rightPlaceholderController.delegate = self;
    self.drillDownController.rightPlaceholderController = rightPlaceholderController;
    
    return YES;
}

#pragma mark - Demo controller delegate

- (void)demoControllerDidRequestPush:(SGBDemoController *)demoController
{
    SGBDemoController *topController = [[self.drillDownController viewControllers] lastObject];
    SGBDemoController *nextController = [[SGBDemoController alloc] initWithNumber:topController.number + 1];
    nextController.delegate = self;
    [self.drillDownController pushViewController:nextController animated:YES completion:nil];
}

- (void)demoControllerDidRequestPop:(SGBDemoController *)demoController
{
    [self.drillDownController popViewControllerAnimated:YES completion:nil];
}

- (void)demoControllerDidRequestPopToRoot:(SGBDemoController *)demoController
{
    [self.drillDownController popToRootViewControllerAnimated:YES completion:nil];
}

- (void)demoControllerDidRequestToggleNavigationBars:(SGBDemoController *)demoController
{
    [self.drillDownController setNavigationBarsHidden:!self.drillDownController.navigationBarsHidden animated:YES];
}

- (void)demoControllerDidRequestToggleToolbars:(SGBDemoController *)demoController
{
    [self.drillDownController setToolbarsHidden:!self.drillDownController.toolbarsHidden animated:YES];
}

@end
