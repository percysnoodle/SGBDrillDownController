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

@property (nonatomic, strong, readwrite) NSMutableArray *leftViewControllers;
@property (nonatomic, strong, readwrite) UIViewController *rightViewController;

@property (nonatomic, strong, readwrite) UIImageView *leftNavigationImageView;
@property (nonatomic, strong, readwrite) UINavigationBar *leftNavigationBar;

@property (nonatomic, strong, readwrite) UIImageView *rightNavigationImageView;
@property (nonatomic, strong, readwrite) UINavigationBar *rightNavigationBar;

@property (nonatomic, strong, readwrite) UIImageView *leftToolbarImageView;
@property (nonatomic, strong, readwrite) UIToolbar *leftToolbar;

@property (nonatomic, strong, readwrite) UIImageView *rightToolbarImageView;
@property (nonatomic, strong, readwrite) UIToolbar *rightToolbar;

@property (nonatomic, assign) BOOL suspendLayout;

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
        _leftViewControllers = [NSMutableArray array];
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
        [self performLayout];
        
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
        [self performLayout];
        
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
    if (self.suspendLayout) return;
    [self performLayout];
}

- (void)performLayout
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
            [self performLayout];
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
            [self performLayout];
        }
    }
}

- (NSArray *)viewControllers
{
    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.leftViewControllers];
    if (self.rightViewController) [viewControllers addObject:self.rightViewController];
    return viewControllers;
}

- (UIViewController *)leftViewController
{
    return [self.leftViewControllers lastObject];
}

- (void)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations completion:(void (^)(BOOL))completion
{
    if (duration > 0)
    {
        self.suspendLayout = YES;
        
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowAnimatedContent
                         animations:animations
                         completion:^(BOOL finished) {
                           
                             self.suspendLayout = NO;
                             if (completion) completion(finished);
                             
                         }];
    }
    else
    {
        if (animations) animations();
        if (completion) completion(YES);
    }
}

- (void)transitionWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animations completion:(void (^)(BOOL))completion
{
    if (duration > 0)
    {
        self.suspendLayout = YES;
        
        [UIView transitionWithView:self.view
                          duration:duration
                            options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionTransitionCrossDissolve
                         animations:animations
                         completion:^(BOOL finished) {
                            
                             self.suspendLayout = NO;
                             if (completion) completion(finished);
                             
                         }];
    }
    else
    {
        if (animations) animations();
        if (completion) completion(YES);
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (!viewController && !self.rightViewController) return;
        
    if ([self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot push a controller that is already in the stack"];
 
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    // Work out what sort of push this is
    BOOL pushingLeftController = (self.viewControllers.count == 0);
    BOOL pushingNewRightController = ((self.viewControllers.count > 0) && (self.rightViewController == nil));
    
    UIViewController *oldLeftController = self.leftViewController;
    UIViewController *oldRightController = self.rightViewController;
    
    if (pushingLeftController)
    {
        [self.leftViewControllers addObject:viewController];
        
        // the first controller obscures the left placeholder
        [self.leftPlaceholderController viewWillDisappear:animated];
    }
    else if (pushingNewRightController)
    {
        self.rightViewController = viewController;
        
        // the second controller obscures the right placeholder
        [self.rightPlaceholderController viewWillDisappear:animated];
    }
    else
    {
        [self.leftViewControllers addObject:oldRightController];
        self.rightViewController = viewController;
        
        // the old left controller will be hidden
        [oldLeftController viewWillDisappear:animated];
    }
    
    if (viewController)
    {
        [viewController willMoveToParentViewController:self];
        [self addChildViewController:viewController];
        
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [containerView addViewToContentView:viewController.view];
        [self.view addSubview:containerView];
    }
    else
    {
        [self.rightPlaceholderController viewWillAppear:animated];
        self.rightPlaceholderController.view.drillDownContainerView.hidden = NO;
    }
    
    if (pushingLeftController)
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
        if (viewController)
        {
            // The new controller will should be sized for the right
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityOffscreenRight];
        }
        else
        {
            [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenRight];
        }
        
        [self.rightNavigationBar setItems:[NSArray arrayWithObjects:viewController.navigationItem, nil] animated:animated];
        self.rightNavigationBar.alpha = 0;
        
        self.rightToolbar.items = viewController.toolbarItems;
        self.rightToolbar.alpha = 0;
        
        if (!pushingNewRightController)
        {
            [self.leftNavigationBar setItems:[self.leftViewControllers valueForKey:@"navigationItem"] animated:animated];
            self.leftNavigationBar.alpha = 0;
            
            self.leftToolbar.items = [self.leftViewController toolbarItems];
            self.leftToolbar.alpha = 0;
        }
    }
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self animateWithDuration:animationDuration animations:^{
        
        self.leftNavigationBar.alpha = 1;
        self.rightNavigationBar.alpha = 1;
        self.leftToolbar.alpha = 1;
        self.rightToolbar.alpha = 1;
            
        if (pushingLeftController)
        {
            // The new controller moves to the left
            [self layoutController:viewController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
            
            // The left placeholder shrinks to the right
            [self layoutController:self.leftPlaceholderController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenRight];
        }
        else
        {
            if (pushingNewRightController)
            {
                // the placeholder shrinks to the left
                [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenLeft];
            }
            else
            {
                // The old left controller shrinks to nothing
                [self layoutController:oldLeftController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenLeft];
                
                // The old right controller moves to the left
                [self layoutController:oldRightController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
            }
            
            if (viewController)
            {
                // The new controller moves to the right
                [self layoutController:viewController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
            }
            else
            {
                [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
            }
        }
        
    } completion:^(BOOL finished) {
        
        self.leftNavigationImageView.image = nil;
        self.rightNavigationImageView.image = nil;
        self.leftToolbarImageView.image = nil;
        self.rightToolbarImageView.image = nil;
        
        if (viewController)
        {
            [viewController didMoveToParentViewController:self];
        }
        else
        {
            [self.rightPlaceholderController viewDidAppear:animated];
        }
        
        if (pushingLeftController)
        {
            // the second controller obscured the right placeholder
            [self.leftPlaceholderController viewDidDisappear:animated];
            self.leftPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        else if (pushingNewRightController)
        {
            // the second controller obscured the right placeholder
            [self.rightPlaceholderController viewDidDisappear:animated];
            self.rightPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        else
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
    BOOL poppingSecondLastController = ((self.viewControllers.count == 2) && (self.rightViewController != nil));
    
    UIViewController *poppedViewController;
    
    if (poppingLastController)
    {
        poppedViewController = self.leftViewController;
        [self.leftViewControllers removeAllObjects];
    }
    else
    {
        poppedViewController = self.rightViewController;
    
        if (poppingSecondLastController)
        {
            self.rightViewController = nil;
        }
        else
        {
            self.rightViewController = [self.leftViewControllers lastObject];
            [self.leftViewControllers removeObject:self.rightViewController];
        }
    }
    
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
    else
    {
        // the new left controller will be revealed
        [newLeftController viewWillAppear:animated];
        newLeftController.view.drillDownContainerView.hidden = NO;
    }
    
    if (!poppingSecondLastController)
    {
        NSArray *newNavigationItems = [self.leftViewControllers valueForKey:@"navigationItem"];
        
        [self.leftNavigationBar setItems:newNavigationItems animated:animated];
        self.leftNavigationBar.alpha = 0;
        
        self.leftToolbar.items = newLeftController.toolbarItems;
        self.leftToolbar.alpha = 0;
    }
    
    // insert a fake item so that the navigation bar does a pop animation
    UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
    fakeItem.hidesBackButton = YES;
    
    if (newRightController)
    {
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem, fakeItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ newRightController.navigationItem ] animated:animated];
    }
    else
    {
        [self.rightNavigationBar setItems:@[ fakeItem ] animated:NO];
        [self.rightNavigationBar setItems:@[] animated:animated];
    }
    self.rightNavigationBar.alpha = 0;
    
    self.rightToolbar.items = newRightController.toolbarItems;
    self.rightToolbar.alpha = 0;
    
    if (poppedViewController)
    {
        [poppedViewController willMoveToParentViewController:nil];
    }
    else
    {
        [self.rightPlaceholderController viewWillDisappear:animated];
    }
    
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
        else if (!poppedViewController)
        {
            // The placeholder shrinks to the right
            [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenRight];
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
        
        if (poppedViewController)
        {
            [poppedViewController removeFromParentViewController];
            [poppedViewController.view.drillDownContainerView removeFromSuperview];
            [poppedViewController.view removeFromSuperview];
            [poppedViewController didMoveToParentViewController:nil];
        }
        else
        {
            [self.rightPlaceholderController viewDidDisappear:animated];
            self.rightPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        
        if (poppingLastController)
        {
            // the left placeholder was revealed
            [self.leftPlaceholderController viewDidAppear:animated];
        }
        else if (poppingSecondLastController)
        {
            // the placeholder was revealed
            [self.rightPlaceholderController viewDidAppear:animated];
        }
        else
        {
            // the new left controller was revealed
            [newLeftController viewDidAppear:animated];
        }
        
        if (completion) completion();
        
    }];
    
    return poppedViewController;
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (viewController == nil) [NSException raise:SGBDrillDownControllerException format:@"Cannot pop to a nil controller"];
    if (![self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot pop to a controller that is not in the stack"];
    
    if ((viewController == self.leftViewController) || (viewController == self.rightViewController))
    {
        // Nothing to do
        if (completion) completion();
        return;
    }
    
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    // Work out what controllers to pop to
    NSInteger indexOfOldLeftViewController = [self.viewControllers indexOfObject:self.leftViewController];
    NSInteger indexOfNewLeftViewController = [self.viewControllers indexOfObject:viewController];
    
    // Special case - one pop
    if (indexOfNewLeftViewController == indexOfOldLeftViewController - 1)
    {
        [self popViewControllerAnimated:animated completion:completion];
        return;
    }
    
    UIViewController *oldLeftController = self.leftViewController;
    UIViewController *oldRightController = self.rightViewController;
    
    UIViewController *newLeftController = viewController;
    UIViewController *newRightController = self.viewControllers[indexOfNewLeftViewController + 1];
    
    NSArray *newLeftViewControllers = [self.leftViewControllers subarrayWithRange:NSMakeRange(0, indexOfNewLeftViewController + 1)];
    // The old left controllers are leaving, except for the new right one, hence +2 not +1
    NSArray * oldLeftViewControllers = [self.leftViewControllers subarrayWithRange:NSMakeRange(indexOfNewLeftViewController + 2, self.leftViewControllers.count - (indexOfNewLeftViewController + 2))];
    
    [self.leftViewControllers removeAllObjects];
    [self.leftViewControllers addObjectsFromArray:newLeftViewControllers];
    self.rightViewController = newRightController;
    
    [newLeftController viewWillAppear:animated];
    newLeftController.view.drillDownContainerView.hidden = NO;
    
    [newRightController viewWillAppear:animated];
    newRightController.view.drillDownContainerView.hidden = NO;
    
    // Fix up the nav and toolbar
    NSArray *newNavigationItems = [self.leftViewControllers valueForKey:@"navigationItem"];
    
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
    
    // The old controllers are going away
    [oldLeftController willMoveToParentViewController:nil];
    
    if (oldRightController)
    {
        [oldRightController willMoveToParentViewController:nil];
    }
    else
    {
        [self.rightPlaceholderController viewWillDisappear:animated];
    }
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self animateWithDuration:animationDuration animations:^{
        
        self.leftNavigationBar.alpha = 1;
        self.rightNavigationBar.alpha = 1;
        self.leftToolbar.alpha = 1;
        self.rightToolbar.alpha = 1;
        
        // The new left one moves to the left
        [self layoutController:newLeftController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityShowing];
        
        // The new right moves right
        [self layoutController:newRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
        
        // The old left moves off
        [self layoutController:oldLeftController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityOffscreenRight];
        
        if (oldRightController)
        {
            // The old right moves off
            [self layoutController:oldRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityOffscreenRight];
        }
        else
        {
            // The right placeholder shrinks
            [self layoutController:self.rightPlaceholderController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityHiddenRight];
        }
        
    } completion:^(BOOL finished) {
        
        for (UIViewController *oldViewController in oldLeftViewControllers)
        {
            [oldViewController removeFromParentViewController];
            [oldViewController.view.drillDownContainerView removeFromSuperview];
            [oldViewController.view removeFromSuperview];
            [oldViewController didMoveToParentViewController:nil];
        }
        
        if (oldRightController)
        {
            [oldRightController removeFromParentViewController];
            [oldRightController.view.drillDownContainerView removeFromSuperview];
            [oldRightController.view removeFromSuperview];
            [oldRightController didMoveToParentViewController:nil];
        }
        else
        {
            [self.rightPlaceholderController viewDidDisappear:animated];
            self.rightPlaceholderController.view.drillDownContainerView.hidden = YES;
        }
        
        [newLeftController viewDidAppear:animated];
        [newRightController viewDidAppear:animated];
        
    }];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.viewControllers.count < 1) return;
    
    [self popToViewController:self.viewControllers[0] animated:animated completion:completion];
}

- (void)replaceRightViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (!self.leftViewController) [NSException raise:SGBDrillDownControllerException format:@"Cannot replace right controller without a left controller"];
    
    if (viewController == self.rightViewController)
    {
        // Nothing to do
        if (completion) completion();
        return;
    }
    
    if (viewController && [self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot replace with a controller that is already in the stack"];
    
    UIViewController *oldRightController = self.rightViewController;
    UIViewController *newRightController = viewController;
    
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    [self.rightNavigationBar setItems:[NSArray arrayWithObjects:newRightController.navigationItem, nil] animated:NO];
    self.rightNavigationBar.alpha = 0;
    
    self.rightToolbar.items = newRightController.toolbarItems;
    self.rightToolbar.alpha = 0;
    
    if (oldRightController)
    {
        self.rightViewController = nil;
    }
    else
    {
        oldRightController = self.rightPlaceholderController;
        [oldRightController viewWillDisappear:animated];
    }
    
    if (newRightController)
    {
        self.rightViewController = newRightController;
        
        [viewController willMoveToParentViewController:self];
        [self addChildViewController:viewController];
        
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [containerView addViewToContentView:viewController.view];
        [self.view addSubview:containerView];
    }
    else
    {
        newRightController = self.rightPlaceholderController;
        [newRightController viewWillAppear:animated];
        newRightController.view.drillDownContainerView.hidden = NO;
    }
    
    // We'll fade the new controller in on the right
    [self layoutController:newRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
    newRightController.view.drillDownContainerView.alpha = 0;
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self transitionWithDuration:animationDuration animations:^{
        
        self.rightNavigationBar.alpha = 1;
        self.rightToolbar.alpha = 1;
        
        oldRightController.view.drillDownContainerView.alpha = 0;
        newRightController.view.drillDownContainerView.alpha = 1;
        
    } completion:^(BOOL finished) {
        
        if (newRightController == self.rightPlaceholderController)
        {
            [newRightController viewDidAppear:animated];
        }
        
        if (oldRightController == self.rightPlaceholderController)
        {
            [self layoutController:oldRightController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenLeft];
            oldRightController.view.drillDownContainerView.hidden = YES;
            [oldRightController viewDidDisappear:animated];
        }
        else
        {
            [oldRightController removeFromParentViewController];
            [oldRightController.view.drillDownContainerView removeFromSuperview];
            [oldRightController.view removeFromSuperview];
            [oldRightController didMoveToParentViewController:nil];
        }
                
    }];
}

- (void)showRightViewController:(UIViewController *)rightViewController
          forLeftViewController:(UIViewController *)leftViewController
                       animated:(BOOL)animated
                     completion:(void (^)(void))completion
{
    if (leftViewController == self.rightViewController)
    {
        [self pushViewController:rightViewController animated:animated completion:completion];
    }
    else
    {
        [self popToViewController:leftViewController animated:animated completion:^{
            
            [self replaceRightViewController:rightViewController animated:animated completion:completion];
            
        }];
    }
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

