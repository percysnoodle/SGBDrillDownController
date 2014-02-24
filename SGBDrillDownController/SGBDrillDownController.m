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
#define kTabBarControllerSelectionKeyPath @"self.tabBarController.selectedViewController"

#define ON_LEGACY_UI ([[[UIDevice currentDevice] systemVersion] integerValue] < 7)

static const CGFloat kSGBDrillDownControllerHidingMaxFadingViewAlpha = 0.20;
static const CGFloat kSGBDrillDownControllerParallaxFactor = 0.30;

CGRect SGBDrillDownControllerLeftParallaxFrame(CGRect leftControllerStartingFrame)
{
    return CGRectOffset(leftControllerStartingFrame, leftControllerStartingFrame.size.width * -kSGBDrillDownControllerParallaxFactor, 0.0);
}

CGRect SGBDrillDownControllerRightParallaxFrame(CGRect leftControllerStartingFrame)
{
    return CGRectOffset(leftControllerStartingFrame, leftControllerStartingFrame.size.width * kSGBDrillDownControllerParallaxFactor, 0.0);
}

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

typedef struct
{
    CGRect containerViewFrame;
    CGRect controllerViewFrame;
}
SGBDrillDownChildControllerLayout;

NSString * const SGBDrillDownControllerException = @"SGBDrillDownControllerException";
NSString * const SGBDrillDownControllerWillPushNotification = @"SGBDrillDownControllerWillPushNotification";
NSString * const SGBDrillDownControllerDidPushNotification = @"SGBDrillDownControllerDidPushNotification";
NSString * const SGBDrillDownControllerWillPopNotification = @"SGBDrillDownControllerWillPopNotification";
NSString * const SGBDrillDownControllerDidPopNotification = @"SGBDrillDownControllerDidPopNotification";
NSString * const SGBDrillDownControllerWillReplaceNotification = @"SGBDrillDownControllerWillReplaceNotification";
NSString * const SGBDrillDownControllerDidReplaceNotification = @"SGBDrillDownControllerDidReplaceNotification";

@interface SGBDrillDownController () <UINavigationBarDelegate, UIToolbarDelegate>

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
@property (nonatomic, assign) BOOL isKVOObservingParent;

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
        _leftViewControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (self.isKVOObservingParent)
    {
        [self removeObserver:self forKeyPath:kTabBarControllerSelectionKeyPath context:nil];
        self.isKVOObservingParent = NO;
    }
}

- (UITabBarItem *)tabBarItem
{
    if ((self.leftViewControllers.count > 0) && [self.leftViewControllers[0] tabBarItem])
    {
        return [self.leftViewControllers[0] tabBarItem];
    }
    
    return [super tabBarItem];
}

- (UINavigationItem *)navigationItem
{
    if ((self.leftViewControllers.count > 0) && [self.leftViewControllers[0] navigationItem])
    {
        return [self.leftViewControllers[0] navigationItem];
    }
    
    return [super navigationItem];
}

#pragma mark - Parent controller

// This duplicates UINavigationController's behaviour whereby it will pop to the root if the tab
// bar button is tapped. With thanks to rdelmar at http://stackoverflow.com/a/16488929/15371

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (self.isKVOObservingParent)
    {
        [self removeObserver:self forKeyPath:kTabBarControllerSelectionKeyPath context:nil];
        self.isKVOObservingParent = NO;
    }
    
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if ([self.parentViewController isKindOfClass:[UITabBarController class]])
    {
        [self addObserver:self forKeyPath:kTabBarControllerSelectionKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        self.isKVOObservingParent = YES;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:kTabBarControllerSelectionKeyPath] && [change[@"old"] isEqual:change[@"new"]] && [change[@"new"] isEqual:self])
    {
        [self popToRootViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Navigation and toolbars

- (void)setNavigationBarsHidden:(BOOL)navigationBarsHidden
{
    [self setNavigationBarsHidden:navigationBarsHidden animated:NO];
}

- (void)setNavigationBarsHidden:(BOOL)navigationBarsHidden animated:(BOOL)animated
{
    if (!navigationBarsHidden)
    {
        self.leftNavigationBar.hidden = NO;
        self.leftNavigationImageView.hidden = NO;
        self.rightNavigationBar.hidden = NO;
        self.rightNavigationImageView.hidden = NO;
    }
    
    NSTimeInterval duration = animated ? UINavigationControllerHideShowBarDuration : 0;
    [self animateWithDuration:duration animations:^{
        
        _navigationBarsHidden = navigationBarsHidden;
        [self performLayout];
        
    } completion:^(BOOL finished) {
        
        if (navigationBarsHidden)
        {
            self.leftNavigationBar.hidden = YES;
            self.leftNavigationImageView.hidden = YES;
            self.rightNavigationBar.hidden = YES;
            self.rightNavigationImageView.hidden = YES;
        }
        
    }];
}

- (void)setToolbarsHidden:(BOOL)toolbarsHidden
{
    [self setToolbarsHidden:toolbarsHidden animated:NO];
}

- (void)setToolbarsHidden:(BOOL)toolbarsHidden animated:(BOOL)animated
{
    if (!toolbarsHidden)
    {
        self.leftToolbar.hidden = NO;
        self.leftToolbarImageView.hidden = NO;
        self.rightToolbar.hidden = NO;
        self.rightToolbarImageView.hidden = NO;
    }
    
    NSTimeInterval duration = animated ? UINavigationControllerHideShowBarDuration : 0;
    [self animateWithDuration:duration animations:^{
        
        _toolbarsHidden = toolbarsHidden;
        [self performLayout];
        
    } completion:^(BOOL finished) {
        
        if (toolbarsHidden)
        {
            self.leftToolbar.hidden = YES;
            self.leftToolbarImageView.hidden = YES;
            self.rightToolbar.hidden = YES;
            self.rightToolbarImageView.hidden = YES;
        }
        
    }];
}

#pragma mark - View loading / unloading

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    if (ON_LEGACY_UI)
    {
        self.leftNavigationImageView = [[UIImageView alloc] init];
        self.leftNavigationImageView.hidden = self.navigationBarsHidden;
        [self.view addSubview:self.leftNavigationImageView];
    }
    
    self.leftNavigationBar = [[self.navigationBarClass alloc] init];
    self.leftNavigationBar.delegate = self;
    self.leftNavigationBar.hidden = self.navigationBarsHidden;
    [self.view addSubview:self.leftNavigationBar];
    
    if (ON_LEGACY_UI)
    {
        self.rightNavigationImageView = [[UIImageView alloc] init];
        self.rightNavigationImageView.hidden = self.navigationBarsHidden;
        [self.view addSubview:self.rightNavigationImageView];
    }
    
    self.rightNavigationBar = [[self.navigationBarClass alloc] init];
    self.rightNavigationBar.delegate = self;
    self.rightNavigationBar.hidden = self.navigationBarsHidden;
    [self.view addSubview:self.rightNavigationBar];
    
    if (ON_LEGACY_UI)
    {
        self.leftToolbarImageView = [[UIImageView alloc] init];
        self.leftToolbarImageView.hidden = self.toolbarsHidden;
        [self.view addSubview:self.leftToolbarImageView];
    }
    
    self.leftToolbar = [[self.toolbarClass alloc] init];
    self.leftToolbar.delegate = self;
    self.leftToolbar.hidden = self.toolbarsHidden;
    [self.view addSubview:self.leftToolbar];
    
    if (ON_LEGACY_UI)
    {
        self.rightToolbarImageView = [[UIImageView alloc] init];
        self.rightToolbarImageView.hidden = self.toolbarsHidden;
        [self.view addSubview:self.rightToolbarImageView];
    }
    
    self.rightToolbar = [[self.toolbarClass alloc] init];
    self.rightToolbar.delegate = self;
    self.rightToolbar.hidden = self.toolbarsHidden;
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
    [super viewDidUnload];

    self.leftNavigationBar = nil;
    self.rightNavigationBar = nil;
    
    [self removePlaceholderFromContainer:self.leftPlaceholderController];
    [self removePlaceholderFromContainer:self.rightPlaceholderController];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Perform the layout before calling super, so that children can get correct sizes in their viewWillAppear.
    [self performLayout];
    [super viewWillAppear:animated];
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
    
    CGFloat navigationBarHeight = ON_LEGACY_UI ? 44 : 64;
    if (self.navigationBarsHidden) top -= navigationBarHeight;
    
    CGRect frame;
    
    switch (position)
    {
        case SGBDrillDownControllerPositionLeft:
            frame = CGRectMake(0, top, self.leftControllerWidth, navigationBarHeight);
            break;
            
        case SGBDrillDownControllerPositionRight:
            frame = CGRectMake(self.leftControllerWidth, top, self.view.bounds.size.width - self.leftControllerWidth, navigationBarHeight);
            break;
    }
    
    navigationBar.frame = frame;
    imageView.frame = frame;
}

- (void)layoutToolbar:(UIToolbar *)toolbar imageView:(UIImageView *)imageView atPosition:(SGBDrillDownControllerPosition)position
{
    CGFloat top = self.view.bounds.size.height;
    if ([self respondsToSelector:@selector(bottomLayoutGuide)])
    {
        top -= [self.bottomLayoutGuide length];
    }
    
    CGFloat toolbarHeight = 44;
    if (!self.toolbarsHidden) top -= toolbarHeight;
    
    CGRect frame;
    
    switch (position)
    {
        case SGBDrillDownControllerPositionLeft:
            frame = CGRectMake(0, top, self.leftControllerWidth, toolbarHeight);
            break;
            
        case SGBDrillDownControllerPositionRight:
            frame = CGRectMake(self.leftControllerWidth, top, self.view.bounds.size.width - self.leftControllerWidth, toolbarHeight);
            break;
    }
    
    toolbar.frame = frame;
    imageView.frame = frame;
}

- (void)bringBarsToFront
{
    [self.view bringSubviewToFront:self.leftNavigationImageView];
    [self.view bringSubviewToFront:self.leftNavigationBar];
    
    [self.view bringSubviewToFront:self.rightNavigationImageView];
    [self.view bringSubviewToFront:self.rightNavigationBar];
    
    [self.view bringSubviewToFront:self.leftToolbarImageView];
    [self.view bringSubviewToFront:self.leftToolbar];
    
    [self.view bringSubviewToFront:self.rightToolbarImageView];
    [self.view bringSubviewToFront:self.rightToolbar];
}

- (void)layoutController:(UIViewController *)controller
              atPosition:(SGBDrillDownControllerPosition)position
              visibility:(SGBDrillDownControllerVisibility)visibility
{
    if (!controller) return;

    controller.view.autoresizingMask = UIViewAutoresizingNone;

    SGBDrillDownChildControllerLayout layout = [self layoutForController:controller
                                                              atPosition:position
                                                              visibility:visibility];
    if (!CGRectIsEmpty(layout.containerViewFrame) || !CGRectIsEmpty(layout.controllerViewFrame))
    {
        controller.view.frame = layout.controllerViewFrame;
        controller.view.drillDownContainerView.frame = layout.containerViewFrame;
    }
}

- (SGBDrillDownChildControllerLayout)layoutForController:(UIViewController *)controller
                                              atPosition:(SGBDrillDownControllerPosition)position
                                              visibility:(SGBDrillDownControllerVisibility)visibility
{
    if (!controller) return (SGBDrillDownChildControllerLayout){CGRectZero, CGRectZero};
    
    CGFloat top = 0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    if ([self respondsToSelector:@selector(bottomLayoutGuide)])
    {
        height -= [self.bottomLayoutGuide length];
    }
    
    if (!self.navigationBarsHidden)
    {
        CGFloat navigationBarHeight = ON_LEGACY_UI ? 44 : 64;
        top += navigationBarHeight;
        height -= navigationBarHeight;
    }
    
    if (!self.toolbarsHidden)
    {
        CGFloat toolbarHeight = 44;
        height -= toolbarHeight;
    }
    
    CGFloat containerLeft = 0, viewLeft = 0;
    CGFloat viewWidth = 0;
    
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

    return (SGBDrillDownChildControllerLayout){
        CGRectMake(containerLeft, top, containerWidth, height),
        CGRectMake(viewLeft, 0, viewWidth, height)
    };
}

- (void)viewDidLayoutSubviews
{
    if (self.suspendLayout) return;
    [self performLayout];
    
    // Autolayout workaround. Yuck.
    [self.view layoutSubviews];
    
    [super viewDidLayoutSubviews];
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
    
    [self bringBarsToFront];
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
    }
}

- (void)addPlaceholderToContainer:(UIViewController *)placeholderController
{
    if (placeholderController)
    {
        [self addChildViewController:placeholderController];
        
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [self.view insertSubview:containerView atIndex:0];
        [containerView addViewToContentView:placeholderController.view];
        
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
    if ([self.viewControllers containsObject:viewController])
    {
        [NSException raise:SGBDrillDownControllerException format:@"Cannot push a controller that is already in the stack"];
    }
    else if (viewController || self.rightViewController)
    {
        if (ON_LEGACY_UI)
        {
            // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
            self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
            self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
            self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
            self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
        }

        SGBDrillDownContainerView *viewControllerContainer = nil;
        if (viewController)
        {
            [self addChildViewController:viewController];
            viewControllerContainer = [[SGBDrillDownContainerView alloc] init];
            [viewControllerContainer addViewToContentView:viewController.view];
            [self.view addSubview:viewControllerContainer];
            //[viewController beginAppearanceTransition:YES animated:animated];
          //NSLog(@"viewController beginTransition %@", viewController);
        }

        UIViewController *oldLeftController = self.leftViewController;
        SGBDrillDownContainerView *oldLeftContainerView = nil;
        UIViewController *oldRightController = self.rightViewController;
        SGBDrillDownContainerView *oldRightContainerView = nil;

        BOOL pushingLeftController = (self.viewControllers.count == 0);
        BOOL pushingNewRightController = ((self.viewControllers.count > 0) && (self.rightViewController == nil));

        if (pushingLeftController)
        {
            [self.leftViewControllers addObject:viewController];

            [viewControllerContainer addShadowViewAtPosition:SGBDrillDownContainerShadowBoth];

            [self layoutController:viewController
                        atPosition:SGBDrillDownControllerPositionLeft
                        visibility:SGBDrillDownControllerVisibilityOffscreenLeft];

            if (self.leftPlaceholderController)
            {
                [self.leftPlaceholderController beginAppearanceTransition:NO animated:animated];
                SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                [leftPlaceholderContainer addFadingView];
                [leftPlaceholderContainer setFadingViewAlpha:0.0];

                if (self.rightPlaceholderController)
                {
                    SGBDrillDownContainerView *rightPlaceholderView = self.rightPlaceholderController.view.drillDownContainerView;
                    [self.view insertSubview:leftPlaceholderContainer belowSubview:rightPlaceholderView];
                }
            }
        }
        else if (pushingNewRightController)
        {
            self.rightViewController = viewController;

            [viewControllerContainer addShadowViewAtPosition:SGBDrillDownContainerShadowBoth];

            [self layoutController:viewController
                        atPosition:SGBDrillDownControllerPositionRight
                        visibility:SGBDrillDownControllerVisibilityOffscreenRight];

            if (self.rightPlaceholderController)
            {
                [self.rightPlaceholderController beginAppearanceTransition:NO animated:animated];
                SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                [rightPlaceholderContainer addFadingView];
                [rightPlaceholderContainer setFadingViewAlpha:0.0];
            }
        }
        else
        {
            [self.leftViewControllers addObject:oldRightController];
            self.rightViewController = viewController;

            oldRightContainerView = oldRightController.view.drillDownContainerView;
            [oldRightContainerView addShadowViewAtPosition:SGBDrillDownContainerShadowLeft];

            if (viewController)
            {
                [self layoutController:viewController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityOffscreenRight];
                [viewControllerContainer addFadingView];
                [viewControllerContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
            }
            else if (self.rightPlaceholderController)
            {
                [self.rightPlaceholderController beginAppearanceTransition:YES animated:animated];
                [self layoutController:self.rightPlaceholderController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityShowing];
                SGBDrillDownContainerView *rightPlaceholderView = self.rightPlaceholderController.view.drillDownContainerView;
                rightPlaceholderView.frame = SGBDrillDownControllerRightParallaxFrame(rightPlaceholderView.frame);
                [rightPlaceholderView addFadingView];
                [rightPlaceholderView setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                rightPlaceholderView.hidden = NO;
            }

            [oldLeftController beginAppearanceTransition:NO animated:animated];
            oldLeftContainerView = oldLeftController.view.drillDownContainerView;
            [oldLeftContainerView addFadingView];
            [oldLeftContainerView setFadingViewAlpha:0.0];

            [self.view bringSubviewToFront:oldRightController.view.drillDownContainerView];

            [viewControllerContainer addShadowViewAtPosition:SGBDrillDownContainerShadowBoth];
            [self.view bringSubviewToFront:viewControllerContainer];
        }

        if (pushingLeftController)
        {
            // The controller's coming in from the left, so we want a pop animation
            UINavigationItem *fakeItem = [[UINavigationItem alloc] init];
            fakeItem.hidesBackButton = YES;
            [self.leftNavigationBar setItems:@[ viewController.navigationItem, fakeItem ] animated:NO];
            [self.leftNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
            if (ON_LEGACY_UI) self.leftNavigationBar.alpha = 0;

            self.leftToolbar.items = viewController.toolbarItems;
            if (ON_LEGACY_UI) self.leftToolbar.alpha = 0;
        }
        else
        {

          [self.rightNavigationBar setItems:[NSArray arrayWithObjects:viewController.navigationItem, nil] animated:animated];
          if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 0;

          self.rightToolbar.items = viewController.toolbarItems;
          if (ON_LEGACY_UI) self.rightToolbar.alpha = 0;

          if (!pushingNewRightController)
          {
              [self.leftNavigationBar setItems:[self.leftViewControllers valueForKey:@"navigationItem"] animated:animated];
              if (ON_LEGACY_UI) self.leftNavigationBar.alpha = 0;

              self.leftToolbar.items = [self.leftViewController toolbarItems];
              if (ON_LEGACY_UI) self.leftToolbar.alpha = 0;
          }
        }

        [self bringBarsToFront];

        NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
        [self animateWithDuration:animationDuration
         animations:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillPushNotification object:self];

            if (ON_LEGACY_UI)
            {
                self.leftNavigationBar.alpha = 1;
                self.rightNavigationBar.alpha = 1;
                self.leftToolbar.alpha = 1;
                self.rightToolbar.alpha = 1;
            }

            if (pushingLeftController)
            {
                [self layoutController:viewController
                            atPosition:SGBDrillDownControllerPositionLeft
                            visibility:SGBDrillDownControllerVisibilityShowing];
                if (self.leftPlaceholderController)
                {
                    SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                    [leftPlaceholderContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                    leftPlaceholderContainer.frame = SGBDrillDownControllerRightParallaxFrame(leftPlaceholderContainer.frame);
                }
            }
            else if (pushingNewRightController)
            {
                [self layoutController:viewController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityShowing];
                if (self.rightPlaceholderController)
                {
                    SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                    [rightPlaceholderContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                    rightPlaceholderContainer.frame = SGBDrillDownControllerLeftParallaxFrame(rightPlaceholderContainer.frame);
                }
            }
            else
            {
                [oldLeftContainerView setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                oldLeftContainerView.frame = SGBDrillDownControllerLeftParallaxFrame(oldLeftContainerView.frame);

                [self layoutController:oldRightController
                            atPosition:SGBDrillDownControllerPositionLeft
                            visibility:SGBDrillDownControllerVisibilityShowing];

                UIViewController *newRightController = (viewController ? viewController : self.rightPlaceholderController);
                if (newRightController)
                {
                    [self layoutController:newRightController
                                atPosition:SGBDrillDownControllerPositionRight
                                visibility:SGBDrillDownControllerVisibilityShowing];
                    SGBDrillDownContainerView *rightContainerView = newRightController.view.drillDownContainerView;
                    [rightContainerView setFadingViewAlpha:0.0];
                }
            }
         }
         completion:^(BOOL finished) {
             if (ON_LEGACY_UI)
             {
                 self.leftNavigationImageView.image = nil;
                 self.rightNavigationImageView.image = nil;
                 self.leftToolbarImageView.image = nil;
                 self.rightToolbarImageView.image = nil;
             }

             if (pushingLeftController)
             {
                 [viewControllerContainer removeShadowView];
                 if (self.leftPlaceholderController)
                 {
                     [self.leftPlaceholderController endAppearanceTransition];
                     SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                     [leftPlaceholderContainer removeFadingView];
                     leftPlaceholderContainer.hidden = YES;
                 }
             }
             else if (pushingNewRightController)
             {
                 [viewControllerContainer removeShadowView];
                 if (self.rightPlaceholderController)
                 {
                     [self.rightPlaceholderController endAppearanceTransition];
                     SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                     [rightPlaceholderContainer removeFadingView];
                     rightPlaceholderContainer.hidden = YES;
                 }
             }
             else
             {
                 [oldLeftController endAppearanceTransition];
                 [oldLeftContainerView removeFadingView];
                 oldLeftContainerView.hidden = YES;

                 [oldRightContainerView removeShadowView];

                 [viewControllerContainer removeShadowView];

                 if (viewController)
                 {
                     [viewControllerContainer removeFadingView];
                 }
                 else if (self.rightPlaceholderController)
                 {
                     [self.rightPlaceholderController endAppearanceTransition];
                     SGBDrillDownContainerView *rightPlaceholderView = self.rightPlaceholderController.view.drillDownContainerView;
                     [rightPlaceholderView removeFadingView];
                 }
             }

             if (completion) completion();

             [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerDidPushNotification object:self];
         }];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    return [self popViewControllerAnimated:animated additionalAnimations:nil completion:completion];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated additionalAnimations:(void (^)(void))additionalAnimations completion:(void (^)(void))completion
{
    UIViewController *poppedViewController = nil;
    if (self.viewControllers.count)
    {
        if (ON_LEGACY_UI)
        {
            // Snapshot the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
            self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
            self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
            self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
            self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
        }

        BOOL poppingLastController = (self.viewControllers.count == 1);
        BOOL poppingSecondLastController = ((self.viewControllers.count == 2) && (self.rightViewController != nil));

        UIViewController *lastViewController = nil;
        SGBDrillDownContainerView *lastViewContainer = nil;
        UIViewController *secondToLastViewController = nil;
        SGBDrillDownContainerView *secondToLastViewContainer = nil;
        UIViewController *newRightController = nil;
        SGBDrillDownContainerView *newRightContainer = nil;
        UIViewController *newLeftController = nil;
        SGBDrillDownContainerView *newLeftContainer = nil;
        UIViewController *oldRightController = nil;

        if (poppingLastController)
        {
            lastViewController = [self.viewControllers firstObject];
            lastViewContainer = lastViewController.view.drillDownContainerView;
            [lastViewContainer addShadowViewAtPosition:SGBDrillDownContainerShadowRight];

            if (self.leftPlaceholderController)
            {
                [self.leftPlaceholderController beginAppearanceTransition:YES animated:animated];
                [self layoutController:self.leftPlaceholderController
                            atPosition:SGBDrillDownControllerPositionLeft
                            visibility:SGBDrillDownControllerVisibilityShowing];
                SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                leftPlaceholderContainer.frame = SGBDrillDownControllerRightParallaxFrame(leftPlaceholderContainer.frame);
                leftPlaceholderContainer.hidden = NO;
                [leftPlaceholderContainer addFadingView];
                [leftPlaceholderContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];

                [self.view insertSubview:leftPlaceholderContainer belowSubview:lastViewContainer];

                if (self.rightPlaceholderController)
                {
                  SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                  [self.view insertSubview:rightPlaceholderContainer aboveSubview:leftPlaceholderContainer];
                }
            }

            poppedViewController = lastViewController;
            [self.leftViewControllers removeLastObject];
        }
        else if (poppingSecondLastController)
        {
            secondToLastViewController = [self.viewControllers lastObject];
            secondToLastViewContainer = secondToLastViewController.view.drillDownContainerView;
            [secondToLastViewContainer addShadowViewAtPosition:SGBDrillDownContainerShadowLeft];
            [self.view bringSubviewToFront:secondToLastViewContainer];

            if (self.rightPlaceholderController)
            {
                [self.rightPlaceholderController beginAppearanceTransition:YES animated:animated];
                [self layoutController:self.rightPlaceholderController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityShowing];
                SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                rightPlaceholderContainer.frame = SGBDrillDownControllerLeftParallaxFrame(rightPlaceholderContainer.frame);
                rightPlaceholderContainer.hidden = NO;
                [rightPlaceholderContainer addFadingView];
                [rightPlaceholderContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
            }

            poppedViewController = secondToLastViewController;
            self.rightViewController = nil;
        }
        else
        {
            newLeftController = self.leftViewControllers[self.leftViewControllers.count - 2];
            [newLeftController beginAppearanceTransition:YES animated:animated];
            [self layoutController:newLeftController
                        atPosition:SGBDrillDownControllerPositionLeft
                        visibility:SGBDrillDownControllerVisibilityShowing];

            newLeftContainer = newLeftController.view.drillDownContainerView;
            newLeftContainer.frame = SGBDrillDownControllerLeftParallaxFrame(newLeftContainer.frame);
            [newLeftContainer addFadingView];
            [newLeftContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
            newLeftContainer.hidden = NO;

            newRightController = self.leftViewController;
            newRightContainer = newRightController.view.drillDownContainerView;
            [newRightContainer addShadowViewAtPosition:SGBDrillDownContainerShadowBoth];
            [self.view insertSubview:newRightContainer aboveSubview:newLeftContainer];

            oldRightController = (self.rightViewController ? self.rightViewController : self.rightPlaceholderController);
            if (oldRightController)
            {
                SGBDrillDownContainerView *oldRightContainer = oldRightController.view.drillDownContainerView;
                [oldRightContainer addFadingView];
                [oldRightContainer setFadingViewAlpha:0.0];
                [self.view insertSubview:oldRightContainer belowSubview:newLeftContainer];
            }

            poppedViewController = self.rightViewController;
            self.rightViewController = newRightController;
            [self.leftViewControllers removeLastObject];
        }

        [poppedViewController beginAppearanceTransition:NO animated:animated];

        if (!poppingSecondLastController)
        {
            NSArray *newNavigationItems = [self.leftViewControllers valueForKey:@"navigationItem"];

            [self.leftNavigationBar setItems:newNavigationItems animated:animated];
            if (ON_LEGACY_UI) self.leftNavigationBar.alpha = 0;

            self.leftToolbar.items = newLeftController.toolbarItems;
            if (ON_LEGACY_UI) self.leftToolbar.alpha = 0;
        }

        // We use a fake item so that the navigation bar does a pop animation
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
        if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 0;

        self.rightToolbar.items = newRightController.toolbarItems;
        if (ON_LEGACY_UI) self.rightToolbar.alpha = 0;

        [self bringBarsToFront];

        NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;

        [self animateWithDuration:animationDuration
         animations:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillPopNotification object:self];

            if (ON_LEGACY_UI)
            {
                self.leftNavigationBar.alpha = 1;
                self.rightNavigationBar.alpha = 1;
                self.leftToolbar.alpha = 1;
                self.rightToolbar.alpha = 1;
            }

            if (poppingLastController)
            {
                [self layoutController:lastViewController
                            atPosition:SGBDrillDownControllerPositionLeft
                            visibility:SGBDrillDownControllerVisibilityOffscreenLeft];
                if (self.leftPlaceholderController)
                {
                    [self layoutController:self.leftPlaceholderController
                                atPosition:SGBDrillDownControllerPositionLeft
                                visibility:SGBDrillDownControllerVisibilityShowing];
                    SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                    [leftPlaceholderContainer setFadingViewAlpha:0.0];
                }
            }
            else if (poppingSecondLastController)
            {
                [self layoutController:secondToLastViewController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityOffscreenRight];

                if (self.rightPlaceholderController)
                {
                    [self layoutController:self.rightPlaceholderController
                                atPosition:SGBDrillDownControllerPositionRight
                                visibility:SGBDrillDownControllerVisibilityShowing];
                    SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                    [rightPlaceholderContainer setFadingViewAlpha:0.0];
                }
            }
            else
            {
                [self layoutController:newLeftController
                            atPosition:SGBDrillDownControllerPositionLeft
                            visibility:SGBDrillDownControllerVisibilityShowing];
                [newLeftContainer setFadingViewAlpha:0.0];

                [self layoutController:newRightController
                            atPosition:SGBDrillDownControllerPositionRight
                            visibility:SGBDrillDownControllerVisibilityShowing];

                if (oldRightController)
                {
                    SGBDrillDownContainerView *oldRightContainer = oldRightController.view.drillDownContainerView;
                    oldRightContainer.frame = SGBDrillDownControllerRightParallaxFrame(oldRightContainer.frame);
                    [oldRightContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                }
            }

            if (additionalAnimations)
            {
                additionalAnimations();
            }

            [poppedViewController willMoveToParentViewController:nil];
        }
        completion:^(BOOL finished) {
            if (poppingLastController)
            {
                lastViewContainer.hidden = YES;
                [lastViewContainer removeShadowView];
                if (self.leftPlaceholderController)
                {
                    [self.leftPlaceholderController endAppearanceTransition];
                    SGBDrillDownContainerView *leftPlaceholderContainer = self.leftPlaceholderController.view.drillDownContainerView;
                    [leftPlaceholderContainer removeFadingView];
                }
            }
            else if (poppingSecondLastController)
            {
                secondToLastViewContainer.hidden = YES;
                [secondToLastViewContainer removeShadowView];

                if (self.rightPlaceholderController)
                {
                    [self.rightPlaceholderController endAppearanceTransition];
                    SGBDrillDownContainerView *rightPlaceholderContainer = self.rightPlaceholderController.view.drillDownContainerView;
                    [rightPlaceholderContainer removeFadingView];
                }
            }
            else
            {
                [newLeftController endAppearanceTransition];

                [newRightContainer removeShadowView];
                [newLeftContainer removeFadingView];

                if (oldRightController)
                {
                    SGBDrillDownContainerView *oldRightContainer = oldRightController.view.drillDownContainerView;
                    [oldRightContainer removeFadingView];
                    oldRightContainer.hidden = YES;
                }
            }

            [poppedViewController endAppearanceTransition];
            [poppedViewController removeFromParentViewController];

            if (completion) completion();

            [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerDidPopNotification object:self];
        }];
    }
    return poppedViewController;
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (viewController == nil) [NSException raise:SGBDrillDownControllerException format:@"Cannot pop to a nil controller"];

    NSUInteger indexOfViewController = [self.leftViewControllers indexOfObject:viewController];
    if (NSNotFound == indexOfViewController) [NSException raise:SGBDrillDownControllerException format:@"Cannot pop to a controller that is not in the stack"];
    
    if ((viewController == self.leftViewController) || (viewController == self.rightViewController))
    {
        // Nothing to do
        if (completion) completion();
    }
    else if (indexOfViewController == self.leftViewControllers.count - 2)
    {
        [self popViewControllerAnimated:animated completion:completion];
    }
    else
    {
      NSMutableArray *leftViewControllers = [[NSMutableArray alloc] init];
      for (NSUInteger i = 0, lastIndex = indexOfViewController + 2; i < lastIndex; ++i)
      {
          [leftViewControllers addObject:self.leftViewControllers[i]];
      }
      NSMutableArray *intermediaryLeftViewControllers = [[NSMutableArray alloc] init];
      for (NSUInteger i = indexOfViewController + 2, count = self.leftViewControllers.count - 1; i < count; ++i)
      {
          UIViewController* intermediateViewController = self.leftViewControllers[i];
          [intermediateViewController beginAppearanceTransition:NO animated:NO];
          [intermediaryLeftViewControllers addObject:intermediateViewController];
      }
      UIViewController *leftViewController = self.leftViewController;
      [leftViewController beginAppearanceTransition:NO animated:animated];

      self.leftViewControllers = leftViewControllers;

      UIViewController *tempLeftViewController = [leftViewControllers lastObject];
      [self layoutController:tempLeftViewController
                  atPosition:SGBDrillDownControllerPositionLeft
                  visibility:SGBDrillDownControllerVisibilityShowing];
      SGBDrillDownContainerView *tempLeftViewContainer = tempLeftViewController.view.drillDownContainerView;
      tempLeftViewContainer.hidden = NO;

      SGBDrillDownContainerView *leftViewContainer = leftViewController.view.drillDownContainerView;
      [self.view bringSubviewToFront:leftViewContainer];
      [self.view insertSubview:tempLeftViewContainer belowSubview:leftViewContainer];
      UIViewController *newLeftViewController = leftViewControllers[leftViewControllers.count - 2];
      SGBDrillDownContainerView *newLeftViewContainer = newLeftViewController.view.drillDownContainerView;
      [self.view insertSubview:newLeftViewContainer belowSubview:leftViewContainer];

      [leftViewContainer addShadowViewAtPosition:SGBDrillDownContainerShadowRight];

      [self popViewControllerAnimated:animated
       additionalAnimations:^{
         [self layoutController:leftViewController
                     atPosition:SGBDrillDownControllerPositionLeft
                     visibility:SGBDrillDownControllerVisibilityOffscreenLeft];
       }
       completion:^{
           for (UIViewController *intermediateViewController in intermediaryLeftViewControllers)
           {
               [intermediateViewController endAppearanceTransition];
               [intermediateViewController removeFromParentViewController];
           }
           [leftViewContainer removeShadowView];
           [leftViewController endAppearanceTransition];
           [leftViewController removeFromParentViewController];

           if (completion)
           {
               completion();
           }
       }];
    }
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
    if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 0;
    
    self.rightToolbar.items = newRightController.toolbarItems;
    if (ON_LEGACY_UI) self.rightToolbar.alpha = 0;
    
    if (oldRightController)
    {
        self.rightViewController = nil;
    }
    else
    {
        oldRightController = self.rightPlaceholderController;
        [oldRightController beginAppearanceTransition:NO animated:animated];
    }
    
    if (newRightController)
    {
        self.rightViewController = newRightController;
        [self addChildViewController:viewController];
        
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [containerView addViewToContentView:viewController.view];
        [self.view addSubview:containerView];
    }
    else
    {
        newRightController = self.rightPlaceholderController;
        [newRightController beginAppearanceTransition:YES animated:animated];
        newRightController.view.drillDownContainerView.hidden = NO;
    }
    
    // We'll fade the new controller in on the right
    [self layoutController:newRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
    newRightController.view.drillDownContainerView.alpha = 0;
    
    [self bringBarsToFront];
    
    NSTimeInterval animationDuration = animated ? kAnimationDuration : 0;
    [self animateWithDuration:animationDuration animations:^{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillReplaceNotification object:self];
        
        if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 1;
        if (ON_LEGACY_UI) self.rightToolbar.alpha = 1;
        
        oldRightController.view.drillDownContainerView.alpha = 0;
        newRightController.view.drillDownContainerView.alpha = 1;
        
    } completion:^(BOOL finished) {
        
        if (newRightController == self.rightPlaceholderController)
        {
            [newRightController endAppearanceTransition];
        }
        
        if (oldRightController == self.rightPlaceholderController)
        {
            [self layoutController:oldRightController atPosition:SGBDrillDownControllerPositionLeft visibility:SGBDrillDownControllerVisibilityHiddenLeft];
            oldRightController.view.drillDownContainerView.hidden = YES;
            [oldRightController endAppearanceTransition];
        }
        else
        {
            [oldRightController.view.drillDownContainerView removeFromSuperview];
            [oldRightController.view removeFromSuperview];
            [oldRightController removeFromParentViewController];
        }
        
        if (completion) completion();
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerDidReplaceNotification object:self];
        
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
            
            if (self.rightViewController)
            {
                [self replaceRightViewController:rightViewController animated:animated completion:completion];
            }
            else
            {
                [self pushViewController:rightViewController animated:animated completion:completion];
            }
            
        }];
    }
}

#pragma mark - Navigation bar delegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if ((bar == self.leftNavigationBar) || (bar == self.rightNavigationBar)) return UIBarPositionTopAttached;
    if ((bar == self.leftToolbar) || (bar == self.rightToolbar)) return UIBarPositionBottom;
    return UIBarPositionAny;
}

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
