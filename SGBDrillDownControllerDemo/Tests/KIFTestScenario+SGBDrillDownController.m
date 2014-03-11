//
//  KIFTestScenario+SGBDrillDownController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 12/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "KIFTestScenario+SGBDrillDownController.h"
#import "KIFTestStep.h"

@implementation KIFTestScenario (SGBDrillDownController)

+ (id)scenarioPushAndPop
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test pushing and popping"];
    
    // If we push a controller we should see its title
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push another we should see both titles
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a third it should hide the first one
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop then the most third one should go away, revealing the first
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop again then the second should go away
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop again then the first should go away
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop again then nothing should happen
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    
    return scenario;
}

+ (id)scenarioBackButton
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test back buttons"];
    
    // Let's start by pushing some controllers
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    
    // There should be two titles and a back button
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitButton]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we tap the back button then the third screen should go away
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Screen 1"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitButton]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    return scenario;
}

+ (id)scenarioPushNil
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test pushing nil"];
    
    // If we push nil then nothing should happen
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push nil!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a controller and push nil then nothing should happen again
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push nil!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push another controller and push nil then the first controller should be hidden
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push nil!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitButton]];
    
    // If we pop then the first controller should be shown
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Screen 1"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitButton]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    return scenario;
}

+ (id)scenarioPopToRoot
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test popping to root"];
    
    // If we pop to root then nothing should happen
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    
    // If we push a controller and pop to root then nothing should happen again
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push another controller and pop to root then nothing should happen yet again
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a third controller and pop to root then we should end up with the first two controllers
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a third and fourth controller and pop to root then we should end up with the first two controllers
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 4 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 4" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a third, fourth and fifth controller and pop to root then we should end up with the first two controllers
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 4 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 5 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop to root!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 4 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 5 View" traits:UIAccessibilityTraitStaticText]];
        
    return scenario;
}

+ (id)scenarioReplace
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test replacing controllers"];
    
    // If we replace with no controllers then nothing should happen
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Replace!"]];
    
    // If we push a controller and replace then we should have a second controler
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Replace!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we replace it again then we should see the new controller
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Replace!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push a third controller and pop to root then we should end up with the two new controllers
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 4 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Replace!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 5 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop then we should see the first controller
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 5 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we pop again then we should see just the first controller
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Pop!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    return scenario;
}

+ (id)scenarioRemove
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test removing controllers"];
    
    // If we remove with no controllers then nothing should happen
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Remove!"]];
    
    // If we push a controller and remove it then nothing should happen again
    
    // If we push a controller and remove then we should have a second controler
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Remove!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    
    // If we push another controller and remove it then we should still have the first controller
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Remove!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];

    // If we push some more controllers and remove one then we should have the last but one
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Remove!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2 View" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 3 View" traits:UIAccessibilityTraitStaticText]];
    
    return scenario;
}

+ (id)scenarioNavigationBarsAndToolbars
{
    KIFTestScenario *scenario = [KIFTestScenario scenarioWithDescription:@"Test navigation bars and toolbars"];
    
    // Let's start by pushing some controllers so we have some titles
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Push!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2" traits:UIAccessibilityTraitStaticText]];
    
    // If we hide the nav bars, the titles should go away
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Toggle navigation bars!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 2" traits:UIAccessibilityTraitStaticText]];
    
    // If we show the toolbars, the titles should come back
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Toggle toolbars!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2" traits:UIAccessibilityTraitStaticText]];
    
    // If we hide the toolbars, the titles should go away
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Toggle toolbars!"]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenceOfViewWithAccessibilityLabel:@"Screen 2" traits:UIAccessibilityTraitStaticText]];
    
    // If we show the nav bars, the titles should come back
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Toggle navigation bars!"]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 1" traits:UIAccessibilityTraitStaticText]];
    [scenario addStep:[KIFTestStep stepToWaitForViewWithAccessibilityLabel:@"Screen 2" traits:UIAccessibilityTraitStaticText]];
    
    return scenario;
}

@end
