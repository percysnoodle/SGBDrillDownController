//
//  SGBDemoTestController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 12/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDemoTestController.h"
#import "KIFTestStep+SGBDrillDownController.h"

@implementation SGBDemoTestController

- (void)initializeScenarios;
{
    [KIFTestScenario setDefaultStepsToSetUp:@[ [KIFTestStep stepToResetWindow] ]];
    
    [self addAllScenarios];
}

@end
