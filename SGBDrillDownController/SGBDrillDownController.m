//
//  SGBDrillDownController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownController.h"

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

- (void)viewDidLayoutSubviews
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    CGFloat leftWidth = self.leftControllerWidth;
    CGFloat rightWidth = width - leftWidth;
    
    CGFloat topHeight = 44;
    CGFloat bottomHeight = height - 44;
    
    self.leftNavigationBar.frame = CGRectMake(0, 0, leftWidth, topHeight);
    self.rightNavigationBar.frame = CGRectMake(leftWidth, 0, rightWidth, topHeight);
    
    for (UIViewController *viewController in self.viewControllers)
    {
        if (viewController == self.rightViewController)
        {
            viewController.view.frame = CGRectMake(0, 0, rightWidth, bottomHeight);
            viewController.view.superview.frame = CGRectMake(leftWidth, topHeight, rightWidth, bottomHeight);
        }
        else if (viewController == self.leftViewController)
        {
            viewController.view.frame = CGRectMake(0, 0, leftWidth, bottomHeight);
            viewController.view.superview.frame = CGRectMake(0, topHeight, leftWidth, bottomHeight);
        }
        else
        {
            viewController.view.frame = CGRectMake(0, 0, leftWidth, bottomHeight);
            viewController.view.superview.frame = CGRectMake(-leftWidth, topHeight, leftWidth, bottomHeight);
        }
    }
    
    if (self.viewControllers.count > 1)
    {
        self.placeholderController.view.frame = CGRectMake(0, 0, rightWidth, bottomHeight);
        self.placeholderController.view.superview.frame = CGRectMake(leftWidth, topHeight, 0, bottomHeight);
    }
    else if (self.viewControllers.count == 1)
    {
        self.placeholderController.view.frame = CGRectMake(0, 0, rightWidth, bottomHeight);
        self.placeholderController.view.superview.frame = CGRectMake(leftWidth, topHeight, rightWidth, bottomHeight);
    }
    else
    {
        self.placeholderController.view.frame = CGRectMake(0, 0, width, bottomHeight);
        self.placeholderController.view.superview.frame = CGRectMake(0, topHeight, width, bottomHeight);
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
        viewController.view.frame = CGRectMake(0, 0, self.leftControllerWidth, self.view.bounds.size.height - 44);
        viewController.view.superview.frame = CGRectMake(self.view.bounds.size.width, 44, self.leftControllerWidth, self.view.bounds.size.height - 44);
        
        // In theory our nav bars should be empty, so we just need to add the new one to the left.
        [self.leftNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
    }
    else
    {
        // The new controller will should be sized for the right
        viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        viewController.view.superview.frame = CGRectMake(self.view.bounds.size.width, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
    
        [self.rightNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
        [self.leftNavigationBar setItems:[oldViewControllers valueForKey:@"navigationItem"] animated:animated];
    }
    
    [self performAnimated:animated animations:^{
            
        // The old left controller shrinks to nothing
        if (pushingGeneralController)
        {
            oldLeftController.view.frame = CGRectMake(0, 0, self.leftControllerWidth, self.view.bounds.size.height - 44);
            oldLeftController.view.superview.frame = CGRectMake(0, 44, 0, self.view.bounds.size.height - 44);
        }
        
        if (pushingFirstController)
        {
            // The new controller moves to the left
            viewController.view.frame = CGRectMake(0, 0, self.leftControllerWidth, self.view.bounds.size.height - 44);
            viewController.view.superview.frame = CGRectMake(0, 44, self.leftControllerWidth, self.view.bounds.size.height - 44);
            
            // The placeholder moves to the right
            self.placeholderController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
            self.placeholderController.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        }
        else
        {
            if (pushingSecondController)
            {
                // the placeholder shrinks to nothing
                self.placeholderController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
                self.placeholderController.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, 0, self.view.bounds.size.height - 44);
            }
            else
            {
                // The old right controller moves to the left
                oldRightController.view.frame = CGRectMake(0, 0, self.leftControllerWidth, self.view.bounds.size.height - 44);
                oldRightController.view.superview.frame = CGRectMake(0, 44, self.leftControllerWidth, self.view.bounds.size.height - 44);
            }
            
            // The new controller moves to the right
            viewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
            viewController.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
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
        UINavigationItem *lastItem = [[UINavigationItem alloc] init];
        lastItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ lastItem ] animated:NO];
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
        newLeftController.view.frame = CGRectMake(0, 0, self.leftControllerWidth, self.view.bounds.size.height - 44);
        newLeftController.view.superview.frame = CGRectMake(0, 44, self.leftControllerWidth, self.view.bounds.size.height - 44);
        
        // The new right controller moves to the right
        newRightController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        newRightController.view.superview.frame = CGRectMake(self.leftControllerWidth, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        
        // The popped controller moves off
        poppedViewController.view.frame = CGRectMake(0, 0, poppedViewController.view.frame.size.width, self.view.bounds.size.height - 44);
        poppedViewController.view.superview.frame = CGRectMake(self.view.bounds.size.width, 44, poppedViewController.view.frame.size.width, self.view.bounds.size.height - 44);
        
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

