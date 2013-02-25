//
//  SGBDrillDownController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownController.h"

typedef enum
{
    SGBDrillDownFull,
    SGBDrillDownLeft,
    SGBDrillDownRight,
    SGBDrillDownHiddenAtLeft,
    SGBDrillDownHiddenAtRight,
    SGBDrillDownOffscreen
    
} SGBDrillDownControllerPosition;

NSString * const SGBDrillDownControllerException = @"SGBDrillDownControllerException";

@interface SGBDrillDownController () <UINavigationBarDelegate>

@property (nonatomic, strong, readwrite) NSArray *viewControllers;

@property (nonatomic, strong, readwrite) UINavigationBar *leftNavigationBar;
@property (nonatomic, strong, readwrite) UINavigationBar *rightNavigationBar;

@end

@implementation SGBDrillDownController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (id)init
{
    return [self initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
}

- (id)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _navigationBarClass = navigationBarClass;
        _toolbarClass = toolbarClass;
        _leftControllerWidth = 320;
        _viewControllers = [NSArray array];
    }
    return self;
}

#pragma mark - View loading / unloading

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.leftNavigationBar = [[self.navigationBarClass alloc] init];
    self.leftNavigationBar.delegate = self;
    [self.view addSubview:self.leftNavigationBar];
    
    self.rightNavigationBar = [[self.navigationBarClass alloc] init];
    self.rightNavigationBar.delegate = self;
    [self.view addSubview:self.rightNavigationBar];
    
    [self addPlaceholderToContainer];
    
    [self.view setNeedsLayout];
}

- (void)viewDidUnload
{
    self.leftNavigationBar = nil;
    self.rightNavigationBar = nil;
    
    [self removePlaceholderFromContainer];
}

#pragma mark - Layout

- (void)showController:(UIViewController *)controller atPosition:(SGBDrillDownControllerPosition)position
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height - 44;
    
    switch (position) {
            
        case SGBDrillDownFull:
            controller.view.frame = CGRectMake(0, 0, width, height);
            controller.view.superview.frame = CGRectMake(0, 44, width, height);
            break;
            
        case SGBDrillDownLeft:
            controller.view.frame = CGRectMake(0, 0, self.leftControllerWidth, height);
            controller.view.superview.frame = CGRectMake(0, 44, self.leftControllerWidth, height);
            break;
     
        case SGBDrillDownRight:
            controller.view.frame = CGRectMake(0, 0, width - self.leftControllerWidth, height);
            controller.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, width - self.leftControllerWidth, height);
            break;
            
        case SGBDrillDownHiddenAtLeft:
            controller.view.frame = CGRectMake(0, 0, self.leftControllerWidth, height);
            controller.view.superview.frame = CGRectMake(0, 44, 0, height);
            break;
            
        case SGBDrillDownHiddenAtRight:
            controller.view.frame = CGRectMake(0, 0, width - self.leftControllerWidth, height);
            controller.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, 0, height);
            break;
            
        case SGBDrillDownOffscreen:
            controller.view.frame = CGRectMake(0, 0, width - self.leftControllerWidth, height);
            controller.view.superview.frame = CGRectMake(width, 44, width - self.leftControllerWidth, height);
            break;
            
    }
}

- (void)viewDidLayoutSubviews
{
    CGFloat leftWidth = self.leftControllerWidth;
    CGFloat rightWidth = self.view.bounds.size.width - leftWidth;
    
    self.leftNavigationBar.frame = CGRectMake(0, 0, leftWidth, 44);
    self.rightNavigationBar.frame = CGRectMake(leftWidth, 0, rightWidth, 44);
    
    for (UIViewController *viewController in self.viewControllers)
    {
        if (viewController == self.rightViewController)
        {
            [self showController:viewController atPosition:SGBDrillDownRight];
        }
        else if (viewController == self.leftViewController)
        {
            [self showController:viewController atPosition:SGBDrillDownLeft];
        }
        else
        {
            [self showController:viewController atPosition:SGBDrillDownHiddenAtLeft];
        }
    }
    
    if (self.viewControllers.count > 1)
    {
        [self showController:self.placeholderController atPosition:SGBDrillDownHiddenAtRight];
    }
    else if (self.viewControllers.count == 1)
    {
        [self showController:self.placeholderController atPosition:SGBDrillDownRight];
    }
    else
    {
        [self showController:self.placeholderController atPosition:SGBDrillDownFull];
    }
}

#pragma mark - Controllers

- (void)removePlaceholderFromContainer
{
    if (self.placeholderController)
    {
        [self.placeholderController willMoveToParentViewController:nil];
        [self.placeholderController.view.superview removeFromSuperview];
        [self.placeholderController.view removeFromSuperview];
        [self.placeholderController removeFromParentViewController];
        [self.placeholderController didMoveToParentViewController:nil];
    }
}

- (void)addPlaceholderToContainer
{
    if (self.placeholderController)
    {
        [self.placeholderController willMoveToParentViewController:self];
        
        UIView *containerView = [[UIView alloc] init];
        containerView.clipsToBounds = YES;
        [self.view insertSubview:containerView atIndex:0];
        
        [containerView addSubview:self.placeholderController.view];
        [self addChildViewController:self.placeholderController];
        [self.placeholderController didMoveToParentViewController:self];
    }
}

- (void)setPlaceholderController:(UIViewController *)placeholderController
{
    if (placeholderController != _placeholderController)
    {
        [self removePlaceholderFromContainer];
        
        _placeholderController = placeholderController;
        
        [self addPlaceholderToContainer];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}

- (UIViewController *)leftViewController
{
    NSUInteger viewControllerCount = self.viewControllers.count;
    if (viewControllerCount > 1) return [self.viewControllers objectAtIndex:(viewControllerCount - 2)];
    else return [self.viewControllers lastObject];
}

- (UIViewController *)rightViewController
{
    if (self.viewControllers.count > 1) return [self.viewControllers lastObject];
    else return nil;
}

- (void)performAnimated:(BOOL)animated animations:(void(^)(void))animations completion:(void (^)(BOOL))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:animations completion:completion];
    }
    else
    {
        if (animations) animations();
        if (completion) completion(YES);
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (viewController == nil) [NSException raise:SGBDrillDownControllerException format:@"Cannot push a nil controller"];
    if ([self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot push a nil controller"];
 
    BOOL pushingFirstController = (self.viewControllers.count == 0);
    BOOL pushingSecondController = (self.viewControllers.count == 1);
    BOOL pushingGeneralController = !pushingFirstController && !pushingSecondController;
    
    UIViewController *oldLeftController = self.leftViewController;
    UIViewController *oldRightController = self.rightViewController;
    NSArray *oldViewControllers = self.viewControllers;
    
    self.viewControllers = [self.viewControllers arrayByAddingObject:viewController];
    
    if (pushingSecondController)
    {
        // the second controller obscures the placeholder
        [self.placeholderController viewWillDisappear:animated];
    }
    else if (pushingGeneralController)
    {
        // the old left controller will be hidden
        [oldLeftController viewWillDisappear:animated];
    }
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    UIView *containerView = [[UIView alloc] init];
    containerView.clipsToBounds = YES;
    [containerView addSubview:viewController.view];
    [self.view addSubview:containerView];
    
    if (pushingFirstController)
    {
        // The new controller should be sized for the left
        [self showController:viewController atPosition:SGBDrillDownHiddenAtLeft];
        
        // The controller's coming in from the left, so we want a pop animation
        UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
        fakeItem.hidesBackButton = YES;
        [self.leftNavigationBar setItems:@[ viewController.navigationItem, fakeItem ] animated:NO];
        [self.leftNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
    }
    else
    {
        // The new controller will should be sized for the right
        [self showController:viewController atPosition:SGBDrillDownOffscreen];
    
        [self.rightNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
        [self.leftNavigationBar setItems:[oldViewControllers valueForKey:@"navigationItem"] animated:animated];
    }
    
    [self performAnimated:animated animations:^{
            
        // The old left controller shrinks to nothing
        if (pushingGeneralController)
        {
            [self showController:oldLeftController atPosition:SGBDrillDownHiddenAtLeft];
        }
        
        if (pushingFirstController)
        {
            // The new controller moves to the left
            [self showController:viewController atPosition:SGBDrillDownLeft];
            
            // The placeholder moves to the right
            [self showController:self.placeholderController atPosition:SGBDrillDownRight];
        }
        else
        {
            if (pushingSecondController)
            {
                // the placeholder shrinks to nothing
                [self showController:self.placeholderController atPosition:SGBDrillDownHiddenAtRight];
            }
            else
            {
                // The old right controller moves to the left
                [self showController:oldRightController atPosition:SGBDrillDownLeft];
            }
            
            // The new controller moves to the right
            [self showController:viewController atPosition:SGBDrillDownRight];
        }
        
    } completion:^(BOOL finished) {
        
        [viewController didMoveToParentViewController:self];
        
        if (pushingSecondController)
        {
            // the second controller obscured the placeholder
            [self.placeholderController viewDidDisappear:animated];
        }
        else if (pushingGeneralController)
        {
            // the old left controller was hidden
            [oldLeftController viewDidDisappear:animated];
        }
        
        if (completion) completion();
        
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.viewControllers.count < 1) return nil;
    
    BOOL poppingLastController = (self.viewControllers.count == 1);
    BOOL poppingSecondLastController = (self.viewControllers.count == 2);
    BOOL poppingGeneralController = !poppingLastController && !poppingSecondLastController;
    
    UIViewController *poppedViewController = [self.viewControllers lastObject];
    
    self.viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)];
    
    UIViewController *newLeftController = self.leftViewController;
    UIViewController *newRightController = self.rightViewController;
    
    if (poppingSecondLastController)
    {
        // the placeholder will be revealed
        [self.placeholderController viewWillAppear:animated];
    }
    else if (poppingGeneralController)
    {
        // the new left controller will be revealed
        [newLeftController viewWillAppear:animated];
    }
    
    if (poppingLastController)
    {
        [self.leftNavigationBar setItems:@[] animated:animated];
    }
    else if (poppingSecondLastController)
    {
        // insert a fake item so that the navigation bar does a pop animation
        UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
        fakeItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ fakeItem ] animated:NO];
        [self.rightNavigationBar setItems:@[] animated:animated];
    }
    else
    {
        NSArray *newNavigationItems = (self.viewControllers.count > 0) ? [[self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)] valueForKey:@"navigationItem"] : @[];
        
        [self.leftNavigationBar setItems:newNavigationItems animated:animated];
        
        // insert a fake item so that the navigation bar does a pop animation
        UINavigationItem *lastItem = [[UINavigationItem alloc] init];
        lastItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem, lastItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem ] animated:animated];
    }
    
    [poppedViewController willMoveToParentViewController:nil];
    
    [self performAnimated:animated animations:^{
        
        if (poppingLastController)
        {
            // The placeholder grows to fill the whole
            self.placeholderController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 44);
            self.placeholderController.view.superview.frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44);
        }
        else if (poppingSecondLastController)
        {
            // The placeholder grows to fill the right
            self.placeholderController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
            self.placeholderController.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        }
        
        // The new left controller moves to the left
        [self showController:newLeftController atPosition:SGBDrillDownLeft];
        
        // The new right controller moves to the right
        [self showController:newRightController atPosition:SGBDrillDownRight];
        
        if (poppingLastController)
        {
            // The popped controller shrinks to nothing
            [self showController:poppedViewController atPosition:SGBDrillDownHiddenAtLeft];
        }
        else
        {
            // The popped controller moves off
            [self showController:poppedViewController atPosition:SGBDrillDownOffscreen];
        }
        
    } completion:^(BOOL finished) {
        
        [poppedViewController removeFromParentViewController];
        [poppedViewController.view removeFromSuperview];
        [poppedViewController didMoveToParentViewController:nil];
        
        if (poppingSecondLastController)
        {
            // the placeholder was revealed
            [self.placeholderController viewDidAppear:animated];
        }
        else if (poppingGeneralController)
        {
            // the new left controller was revealed
            [newLeftController viewDidAppear:animated];
        }
        
        if (completion) completion();
        
    }];
    
    return poppedViewController;
}

#pragma mark - Navigation bar delegate

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    [self popViewControllerAnimated:YES completion:nil];
    return NO;
}

@end

@implementation UIViewController (SGBDrillDownController)

- (SGBDrillDownController *)drillDownController
{
    for (UIViewController *viewController = self.parentViewController; viewController != nil; viewController = viewController.parentViewController)
    {
        if ([viewController isKindOfClass:[SGBDrillDownController class]]) return (SGBDrillDownController *)viewController;
    }
    
    return nil;
}

@end

