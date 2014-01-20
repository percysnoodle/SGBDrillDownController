//
//  SGBDemoTabBarController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 20/01/2014.
//  Copyright (c) 2014 Simon Booth. All rights reserved.
//

#import "SGBDemoTabBarController.h"

@interface SGBDemoTabBarController ()

@end

@implementation SGBDemoTabBarController

- (void)viewDidLayoutSubviews
{
    // Workaround for bug where taps only work in portrait-sized rect even in landscape
    // with thanks to http://stackoverflow.com/questions/3596015/how-to-resize-uiviewcontrollerwrapperview
    self.selectedViewController.view.superview.frame = self.view.bounds;
    [super viewDidLayoutSubviews];
}

@end
