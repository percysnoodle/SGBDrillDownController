//
//  SGBDrillDownController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownController.h"
#import "SGBDrillDownContainerView.h"
#import <QuartzCore/QuartzCore.h>

#define kAnimationDuration 0.33

typedef NS_ENUM(NSInteger, SGBDrillDownControllerPosition)
{
    SGBDrillDownControllerPositionLeft,
    SGBDrillDownControllerPositionRight
    
};

typedef NS_ENUM(NSInteger, SGBDrillDownControllerVisibility)
{
    SGBDrillDownControllerVisibilityOffscreenLeft,
    SGBDrillDownControllerVisibilityHiddenLeft,
    SGBDrillDownControllerVisibilityShowing,
    SGBDrillDownControllerVisibilityHiddenRight,
    SGBDrillDownControllerVisibilityOffscreenRight
};

NSString * const SGBDrillDownControllerException = @"SGBDrillDownControllerException";

@interface SGBDrillDownController () <UINavigationBarDelegate>

@property (nonatomic, strong, readwrite) NSArray *viewControllers;

@property (nonatomic, strong, readwrite) UIImageView *leftNavigationImageView;
@property (nonatomic, strong, readwrite) UINavigationBar *leftNavigationBar;

@property (nonatomic, strong, readwrite) UIImageView *rightNavigationImageView;
@property (nonatomic, strong, readwrite) UINavigationBar *rightNavigationBar;

@property (nonatomic, strong, readwrite) UIImageView *leftToolbarImageView;
@property (nonatomic, strong, readwrite) UIToolbar *leftToolbar;

@property (nonatomic, strong, readwrite) UIImageView *rightToolbarImageView;
@property (nonatomic, strong, readwrite) UIToolbar *rightToolbar;

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
        _toolbarsHidden = YES;
        _leftControllerWidth = 320;
        _viewControllers = [NSArray array];
    }
    return self;
}

- (void)setNavigationBarsHidden:(BOOL)navigationBarsHidden
{
    [self setNavigationBarsHidden:navigationBarsHidden animated:NO];
}

- (void)setNavigationBarsHidden:(BOOL)navigationBarsHidden animated:(BOOL)animated
{
    [self animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        
        _navigationBarsHidden = navigationBarsHidden;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)setToolbarsHidden:(BOOL)toolbarsHidden
{
    [self setToolbarsHidden:toolbarsHidden animated:NO];
}

- (void)setToolbarsHidden:(BOOL)toolbarsHidden animated:(BOOL)animated
{
    [self animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        
        _toolbarsHidden = toolbarsHidden;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - View loading / unloading

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.leftNavigationImageView = [[UIImageView alloc] init];
    [self.view addSubview:self.leftNavigationImageView];
    
    self.leftNavigationBar = [[self.navigationBarClass alloc] init];
    self.leftNavigationBar.delegate = self;
    [self.view addSubview:self.leftNavigationBar];
    
    self.rightNavigationImageView = [[UIImageView alloc] init];
    [self.view addSubview:self.rightNavigationImageView];
    
    self.rightNavigationBar = [[self.navigationBarClass alloc] init];
    self.rightNavigationBar.delegate = self;
    [self.view addSubview:self.rightNavigationBar];
    
    self.leftToolbarImageView = [[UIImageView alloc] init];
    [self.view addSubview:self.leftToolbarImageView];
    
    self.leftToolbar = [[self.toolbarClass alloc] init];
    [self.view addSubview:self.leftToolbar];
    
    self.rightToolbarImageView = [[UIImageView alloc] init];
    [self.view addSubview:self.rightToolbarImageView];
    
    self.rightToolbar = [[self.toolbarClass alloc] init];
    [self.view addSubview:self.rightToolbar];
    
    if (self.leftPlaceholderController)
    {
        [self addPlaceholderToContainer:self.leftPlaceholderController];
    }
    
    if (self.rightPlaceholderController)
    {
        [self addPlaceholderToContainer:self.rightPlaceholderController];
    }
    
    [self.view setNeedsLayout];
}

- (void)viewDidUnload
{
    self.leftNavigationBar = nil;
    self.rightNavigationBar = nil;
    
    [self removePlaceholderFromContainer:self.leftPlaceholderController];
    [self removePlaceholderFromContainer:self.rightPlaceholderController];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Layout

- (void)layoutNavigationBar:(UINavigationBar *)navigationBar imageView:(UIImageView *)imageView atPosition:(SGBDrillDownControllerPosition)position
{
    CGFloat top = 0;
    CGFloat height = 44;
    if (self.navigationBarsHidden) top -= height;
    
    CGRect frame;
    
    switch (position)
    {
        case SGBDrillDownControllerPositionLeft:
            frame = CGRectMake(0, top, self.leftControllerWidth, height);
            break;
            
        case SGBDrillDownControllerPositionRight:
            frame = CGRectMake(self.leftControllerWidth, top, self.view.bounds.size.width - self.leftControllerWidth, height);
            break;
    }
    
    navigationBar.frame = frame;
    imageView.frame = frame;
}

- (void)layoutToolbar:(UIToolbar *)toolbar imageView:(UIImageView *)imageView atPosition:(SGBDrillDownControllerPosition)position
{
    CGFloat top = self.view.bounds.size.height;
    CGFloat height = 44;
    if (!self.toolbarsHidden) top -= height;
    
    CGRect frame;
    
    switch (position)
    {
        case SGBDrillDownControllerPositionLeft:
            frame = CGRectMake(0, top, self.leftControllerWidth, height);
            break;
            
        case SGBDrillDownControllerPositionRight:
            frame = CGRectMake(self.leftControllerWidth, top, self.view.bounds.size.width - self.leftControllerWidth, height);
            break;
    }
    
    toolbar.frame = frame;
    imageView.frame = frame;
}

- (void)layoutController:(UIViewController *)controller
              atPosition:(SGBDrillDownControllerPosition)position
              visibility:(SGBDrillDownControllerVisibility)visibility
{
    CGFloat top = 0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    if (!self.navigationBarsHidden)
    {
        top += 44;
        height -= 44;
    }
    
    if (!self.toolbarsHidden)
    {
        height -= 44;
    }
    
    CGFloat containerLeft = 0, viewLeft = 0;
    CGFloat viewWidth;
    
    switch (position)
    {
        case SGBDrillDownControllerPositionLeft:
            viewWidth = self.leftControllerWidth;
            break;
            
        case SGBDrillDownControllerPositionRight:
            containerLeft = self.leftControllerWidth + 1;
            viewWidth = width - containerLeft;
            break;
    }
    
    
    CGFloat containerWidth = viewWidth;
    
    switch (visibility)
    {
        case SGBDrillDownControllerVisibilityOffscreenLeft:
            viewLeft = -viewWidth;
            containerWidth = 0;
            break;
            
        case SGBDrillDownControllerVisibilityHiddenLeft:
            containerWidth = 0;
            break;
            
        case SGBDrillDownControllerVisibilityShowing:
            break;
            
        case SGBDrillDownControllerVisibilityHiddenRight:
            viewLeft = -viewWidth;
            containerLeft += viewWidth;
            containerWidth = 0;
            break;
            
        case SGBDrillDownControllerVisibilityOffscreenRight:
            containerLeft += viewWidth;
            containerWidth = 0;
            break;
    }
    
    controller.view.frame = CGRectMake(viewLeft, 0, viewWidth, height);
    controller.view.drillDownContainerView.frame = CGRectMake(containerLeft, top, containerWidth, height);
}

- (void)viewDidLayoutSubviews
{
    [self layoutNavigationBar:self.leftNavigationBar imageView:self.leftNavigationImageView atPosition:SGBDrillDownControllerPositionLeft];
    [self layoutNavigationBar:self.rightNavigationBar imageView:self.rightNavigationImageView atPosition:SGBDrillDownControllerPositionRight];
    
    [self layoutToolbar:self.leftToolbar imageView:self.leftToolbarImageView atPosition:SGBDrillDownControllerPositionLeft];
    [self layoutToolbar:self.rightToolbar imageView:self.rightToolbarImageView atPosition:SGBDrillDownControllerPositionRight];
    
    for (UIViewController *viewController in self.viewControllers)
    {
        if (viewController == self.rightViewController)
        {
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
        }
        else if (viewController == self.leftViewController)
        {
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
        }
        else
        {
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenLeft];
        }
    }
    
    if (self.leftViewController)
    {
        [self layoutController:self.leftPlaceholderController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenRight];
    }
    else
    {
        [self layoutController:self.leftPlaceholderController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
    }
    
    if (self.rightViewController)
    {
        [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenLeft];
    }
    else
    {
        [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
    }
}

- (UIImage *)imageForView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, [[UIScreen mainScreen] scale]);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - Controllers

- (void)removePlaceholderFromContainer:(UIViewController *)placeholderController
{
    if (placeholderController)
    {
        [placeholderController willMoveToParentViewController:nil];
        [placeholderController.view.drillDownContainerView removeFromSuperview];
        [placeholderController.view removeFromSuperview];
        [placeholderController removeFromParentViewController];
        [placeholderController didMoveToParentViewController:nil];
    }
}

- (void)addPlaceholderToContainer:(UIViewController *)placeholderController
{
    if (placeholderController)
    {
        [placeholderController willMoveToParentViewController:self];
        
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [self.view insertSubview:containerView atIndex:0];
        
        [containerView addViewToContentView:placeholderController.view];
        [self addChildViewController:placeholderController];
        [placeholderController didMoveToParentViewController:self];
    }
}

- (void)setLeftPlaceholderController:(UIViewController *)leftPlaceholderController
{
    if (leftPlaceholderController != _leftPlaceholderController)
    {
        if (self.isViewLoaded) [self removePlaceholderFromContainer:leftPlaceholderController];
        
        _leftPlaceholderController = leftPlaceholderController;
        
        if (self.isViewLoaded)
        {
            [self addPlaceholderToContainer:leftPlaceholderController];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }
    }
}

- (void)setRightPlaceholderController:(UIViewController *)rightPlaceholderController
{
    if (rightPlaceholderController != _rightPlaceholderController)
    {
        if (self.isViewLoaded) [self removePlaceholderFromContainer:rightPlaceholderController];
        
        _rightPlaceholderController = rightPlaceholderController;
        
        if (self.isViewLoaded)
        {
            [self addPlaceholderToContainer:rightPlaceholderController];
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }
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

- (void)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations completion:(void (^)(BOOL))completion
{
    if (duration > 0)
    {
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowAnimatedContent
                         animations:animations
                         completion:completion];
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
    if ([self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot push a controller that is already in the stack"];
 
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    // Work out what sort of push this is
    BOOL pushingFirstController = (self.viewControllers.count == 0);
    BOOL pushingSecondController = (self.viewControllers.count == 1);
    BOOL pushingGeneralController = !pushingFirstController && !pushingSecondController;
    
    UIViewController *oldLeftController = self.leftViewController;
    UIViewController *oldRightController = self.rightViewController;
    NSArray *oldViewControllers = self.viewControllers;
    
    self.viewControllers = [self.viewControllers arrayByAddingObject:viewController];
    
    if (pushingFirstController)
    {
        // the first controller obscures the left placeholder
        [self.leftPlaceholderController viewWillDisappear:animated];
    }
    if (pushingSecondController)
    {
        // the second controller obscures the right placeholder
        [self.rightPlaceholderController viewWillDisappear:animated];
    }
    else if (pushingGeneralController)
    {
        // the old left controller will be hidden
        [oldLeftController viewWillDisappear:animated];
    }
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
    [containerView addViewToContentView:viewController.view];
    [self.view addSubview:containerView];
    
    if (pushingFirstController)
    {
        // The new controller should be sized for the left
        [self layoutController:viewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityOffscreenLeft];
        
        // The controller's coming in from the left, so we want a pop animation
        UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
        fakeItem.hidesBackButton = YES;
        [self.leftNavigationBar setItems:@[ viewController.navigationItem, fakeItem ] animated:NO];
        [self.leftNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
        self.leftNavigationBar.alpha = 0;
        
        self.leftToolbar.items = viewController.toolbarItems;
        self.leftToolbar.alpha = 0;
    }
    else
    {
        // The new controller will should be sized for the right
        [self layoutController:viewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityOffscreenRight];
        
        [self.rightNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
        self.rightNavigationBar.alpha = 0;
        
        [self.leftNavigationBar setItems:[oldViewControllers valueForKey:@"navigationItem"] animated:animated];
        self.leftNavigationBar.alpha = 0;
        
        self.rightToolbar.items = viewController.toolbarItems;
        self.rightToolbar.alpha = 0;
        
        if (pushingGeneralController)
        {
            self.leftToolbar.items = [[oldViewControllers lastObject] toolbarItems];
            self.leftToolbar.alpha = 0;
        }
    }
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self animateWithDuration:animationDuration animations:^{
        
        self.leftNavigationBar.alpha = 1;
        self.rightNavigationBar.alpha = 1;
        self.leftToolbar.alpha = 1;
        self.rightToolbar.alpha = 1;
            
        // The old left controller shrinks to nothing
        if (pushingGeneralController)
        {
            [self layoutController:oldLeftController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenLeft];
        }
        
        if (pushingFirstController)
        {
            // The new controller moves to the left
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
            
            // The left placeholder shrinks to the right
            [self layoutController:self.leftPlaceholderController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenRight];
        }
        else
        {
            if (pushingSecondController)
            {
                // the placeholder shrinks to the left
                [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenLeft];
            }
            else
            {
                // The old right controller moves to the left
                [self layoutController:oldRightController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
            }
            
            // The new controller moves to the right
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
        }
        
    } completion:^(BOOL finished) {
        
        self.leftNavigationImageView.image = nil;
        self.rightNavigationImageView.image = nil;
        self.leftToolbarImageView.image = nil;
        self.rightToolbarImageView.image = nil;
        
        [viewController didMoveToParentViewController:self];
        
        if (pushingFirstController)
        {
            // the second controller obscured the right placeholder
            [self.leftPlaceholderController viewDidDisappear:animated];
            self.leftPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        else if (pushingSecondController)
        {
            // the second controller obscured the right placeholder
            [self.rightPlaceholderController viewDidDisappear:animated];
            self.rightPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        else if (pushingGeneralController)
        {
            // the old left controller was hidden
            [oldLeftController viewDidDisappear:animated];
            oldLeftController.view.drillDownContainerView.hidden = YES;
        }
        
        if (completion) completion();
        
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.viewControllers.count < 1) return nil;
    
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    // Work out what sort of pop this is
    BOOL poppingLastController = (self.viewControllers.count == 1);
    BOOL poppingSecondLastController = (self.viewControllers.count == 2);
    BOOL poppingGeneralController = !poppingLastController && !poppingSecondLastController;
    
    UIViewController *poppedViewController = [self.viewControllers lastObject];
    
    self.viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)];
    
    UIViewController *newLeftController = self.leftViewController;
    UIViewController *newRightController = self.rightViewController;
    
    if (poppingLastController)
    {
        // the left placeholder will be revealed
        [self.leftPlaceholderController viewWillAppear:animated];
        self.leftPlaceholderController.view.drillDownContainerView.hidden = NO;
    }
    else if (poppingSecondLastController)
    {
        // the placeholder will be revealed
        [self.rightPlaceholderController viewWillAppear:animated];
        self.rightPlaceholderController.view.drillDownContainerView.hidden = NO;
    }
    else if (poppingGeneralController)
    {
        // the new left controller will be revealed
        [newLeftController viewWillAppear:animated];
        newLeftController.view.drillDownContainerView.hidden = NO;
    }
    
    if (poppingLastController)
    {
        [self.leftNavigationBar setItems:@[] animated:animated];
        self.leftNavigationBar.alpha = 0;
        
        self.leftToolbar.items = @[];
        self.leftToolbar.alpha = 0;
    }
    else if (poppingSecondLastController)
    {
        // insert a fake item so that the navigation bar does a pop animation
        UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
        fakeItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ fakeItem ] animated:NO];
        [self.rightNavigationBar setItems:@[] animated:animated];
        self.rightNavigationBar.alpha = 0;
        
        self.rightToolbar.items = @[];
        self.rightToolbar.alpha = 0;
    }
    else
    {
        NSArray *newNavigationItems = (self.viewControllers.count > 0) ? [[self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)] valueForKey:@"navigationItem"] : @[];
        
        [self.leftNavigationBar setItems:newNavigationItems animated:animated];
        self.leftNavigationBar.alpha = 0;
        
        self.leftToolbar.items = newLeftController.toolbarItems;
        self.leftToolbar.alpha = 0;
        
        // insert a fake item so that the navigation bar does a pop animation
        UINavigationItem *lastItem = [[UINavigationItem alloc] init];
        lastItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem, lastItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem ] animated:animated];
        self.rightNavigationBar.alpha = 0;
        
        self.rightToolbar.items = newRightController.toolbarItems;
        self.rightToolbar.alpha = 0;
    }
    
    [poppedViewController willMoveToParentViewController:nil];
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self animateWithDuration:animationDuration animations:^{
        
        self.leftNavigationBar.alpha = 1;
        self.rightNavigationBar.alpha = 1;
        self.leftToolbar.alpha = 1;
        self.rightToolbar.alpha = 1;
        
        if (poppingLastController)
        {
            // The left placeholder grows to fill the left
            [self layoutController:self.leftPlaceholderController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
        }
        else if (poppingSecondLastController)
        {
            // The right placeholder grows to fill the right
            [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
        }
        
        // The new left controller moves to the left
        [self layoutController:newLeftController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
        
        // The new right controller moves to the right
        [self layoutController:newRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
        
        if (poppingLastController)
        {
            // The popped controller moves off to the left
            [self layoutController:poppedViewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityOffscreenLeft];
        }
        else
        {
            // The popped controller moves off to the right
            [self layoutController:poppedViewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityOffscreenRight];
        }
        
    } completion:^(BOOL finished) {
        
        self.leftNavigationBar.alpha = 1;
        self.rightNavigationBar.alpha = 1;
        self.leftToolbar.alpha = 1;
        self.rightToolbar.alpha = 1;
        
        [poppedViewController removeFromParentViewController];
        [poppedViewController.view.drillDownContainerView removeFromSuperview];
        [poppedViewController.view removeFromSuperview];
        [poppedViewController didMoveToParentViewController:nil];
        
        if (poppingLastController)
        {
            // the left placeholder was revealed
            [self.leftPlaceholderController viewDidAppear:animated];
        }
        if (poppingSecondLastController)
        {
            // the placeholder was revealed
            [self.rightPlaceholderController viewDidAppear:animated];
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

