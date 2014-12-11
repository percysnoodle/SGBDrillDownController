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
#import <objc/runtime.h>

static char * const kSGBTabBarControllerKVOObserversKey = "kSGBTabBarControllerKVOObserversKey";
static NSString * const kSGBTabBarControllerSelectedViewControllerKeyPath = @"self.kvoObservedTabBarController.selectedViewController";

#define ON_LEGACY_UI ([[[UIDevice currentDevice] systemVersion] integerValue] < 7)

static const CGFloat kSGBDrillDownControllerAnimationDuration = 0.33;
static const CGFloat kSGBDrillDownControllerHidingMaxFadingViewAlpha = 0.20;
static const CGFloat kSGBDrillDownControllerParallaxFactor = 0.30;

CGAffineTransform SGBDrillDownControllerLeftParallaxTransform(CGFloat maxOffset, CGFloat initialX, CGFloat updatedX, CGAffineTransform transform)
{
    CGFloat dx = fminf(maxOffset, (updatedX - initialX));
    CGFloat translate = dx * kSGBDrillDownControllerParallaxFactor;
    transform.tx = CGAffineTransformMakeTranslation(translate, 0.0).tx;
    return transform;
}

CGRect SGBDrillDownControllerLeftParallaxFrame(CGRect leftControllerStartingFrame)
{
    return CGRectOffset(leftControllerStartingFrame, leftControllerStartingFrame.size.width * -kSGBDrillDownControllerParallaxFactor, 0.0);
}

CGRect SGBDrillDownControllerRightParallaxFrame(CGRect rightControllerStartingFrame)
{
    return CGRectOffset(rightControllerStartingFrame, rightControllerStartingFrame.size.width * kSGBDrillDownControllerParallaxFactor, 0.0);
}

UINavigationItem * SGBDrillDownControllerCreateFakeNavigationItem()
{
    UINavigationItem *item = [[UINavigationItem alloc] init];
    item.hidesBackButton = YES;
    item.title = @"";
    return item;
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
    UIEdgeInsets contentInset;
}
SGBDrillDownChildControllerLayout;

NSString * const SGBDrillDownControllerException = @"SGBDrillDownControllerException";
NSString * const SGBDrillDownControllerWillPushNotification = @"SGBDrillDownControllerWillPushNotification";
NSString * const SGBDrillDownControllerDidPushNotification = @"SGBDrillDownControllerDidPushNotification";
NSString * const SGBDrillDownControllerWillPopNotification = @"SGBDrillDownControllerWillPopNotification";
NSString * const SGBDrillDownControllerDidPopNotification = @"SGBDrillDownControllerDidPopNotification";
NSString * const SGBDrillDownControllerWillReplaceNotification = @"SGBDrillDownControllerWillReplaceNotification";
NSString * const SGBDrillDownControllerDidReplaceNotification = @"SGBDrillDownControllerDidReplaceNotification";

@interface SGBDrillDownContainerAssociatedObject : NSObject

@property (nonatomic, strong) SGBDrillDownController *drillDownController;

@end

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

#ifdef __IPHONE_7_0
@property (nonatomic, strong, readwrite) UIScreenEdgePanGestureRecognizer *swipeBackGestureRecognizer;
#endif

@property (nonatomic, assign) BOOL suspendLayout;
@property (nonatomic, assign) BOOL animatingRotation;

@property (nonatomic, strong, readonly) NSUUID *kvoObserverUUID;
@property (nonatomic, assign) UITabBarController *kvoObservedTabBarController;

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
        self.restorationClass = self.class;
        
        _navigationBarClass = navigationBarClass;
        _navigationBarPosition = UIBarPositionTopAttached;
        _propagatesNavigationItem = YES;
        
        _toolbarClass = toolbarClass;
        _toolbarPosition = UIBarPositionBottom;
        _toolbarsHidden = YES;
        _propagatesTabBarItem = YES;
        
        _leftControllerWidth = 320;
        _leftViewControllers = [[NSMutableArray alloc] init];
        
        _kvoObserverUUID = [NSUUID UUID];
    }
    return self;
}

- (void)dealloc
{
    [self stopKVOObservingParent];
}

- (UITabBarItem *)tabBarItem
{
    if (self.propagatesTabBarItem)
    {
        if ((self.leftViewControllers.count > 0) && [self.leftViewControllers[0] tabBarItem])
        {
            return [self.leftViewControllers[0] tabBarItem];
        }
        else if ([self.leftPlaceholderController tabBarItem])
        {
            return [self.leftPlaceholderController tabBarItem];
        }
    }
    
    return [super tabBarItem];
}

- (UINavigationItem *)navigationItem
{
    if (self.propagatesNavigationItem)
    {
        if ((self.leftViewControllers.count > 0) && [self.leftViewControllers[0] navigationItem])
        {
            return [self.leftViewControllers[0] navigationItem];
        }
    }
    
    return [super navigationItem];
}

#pragma mark - State restoration

// Increment this constant if you making breaking changes to state preservation/restoration.
static const NSInteger kStateRestorationVersion = 1;
static NSString * const kStateRestorationRestorationVersionKey = @"restorationVersion";

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    if (kStateRestorationVersion > [coder decodeIntegerForKey:kStateRestorationRestorationVersionKey])
    {
        NSLog(@"SGBDrillDownController not restoring state because saved restoration state is from a previous version of the preservation/restoration logic.");
        return nil;
    }
    else
    {
        UIViewController *viewController = [[self alloc] init];
        viewController.restorationIdentifier = [identifierComponents lastObject];
        return viewController;
    }
}

static NSString * const kStateRestorationNavigationBarClassNameKey = @"navigationBarClassName";
static NSString * const kStateRestorationToolbarClassNameKey = @"toolbarClassName";
static NSString * const kStateRestorationLeftToolbarKey = @"leftToolbar";
static NSString * const kStateRestorationRightToolbarKey = @"rightToolbar";
static NSString * const kStateRestorationNavigationBarsHiddenKey = @"navigationBarsHidden";
static NSString * const kStateRestorationToolbarsHiddenKey = @"toolbarsHidden";
static NSString * const kStateRestorationLeftControllerWidthKey = @"leftControllerWidth";
static NSString * const kStateRestorationLeftPlaceholderControllerKey = @"leftPlaceholderController";
static NSString * const kStateRestorationRightPlaceholderControllerKey = @"rightPlaceholderController";
static NSString * const kStateRestorationViewControllersKey = @"viewControllers";
static NSString * const kStateRestorationHadRestorableRightViewControllerKey = @"hadRestorableRightViewController";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:kStateRestorationVersion forKey:kStateRestorationRestorationVersionKey];
    
    [coder encodeObject:NSStringFromClass(self.navigationBarClass) forKey:kStateRestorationNavigationBarClassNameKey];
    [coder encodeObject:NSStringFromClass(self.toolbarClass) forKey:kStateRestorationToolbarClassNameKey];
    if (self.leftToolbar)
    {
        [coder encodeObject:self.leftToolbar forKey:kStateRestorationLeftToolbarKey];
    }
    if (self.rightToolbar)
    {
        [coder encodeObject:self.rightToolbar forKey:kStateRestorationRightToolbarKey];
    }
    [coder encodeBool:self.navigationBarsHidden forKey:kStateRestorationNavigationBarsHiddenKey];
    [coder encodeBool:self.toolbarsHidden forKey:kStateRestorationToolbarsHiddenKey];
    [coder encodeFloat:self.leftControllerWidth forKey:kStateRestorationLeftControllerWidthKey];
    if (self.leftPlaceholderController.restorationIdentifier.length)
    {
        [coder encodeObject:self.leftPlaceholderController forKey:kStateRestorationLeftPlaceholderControllerKey];
    }
    if (self.rightPlaceholderController.restorationIdentifier.length)
    {
        [coder encodeObject:self.rightPlaceholderController forKey:kStateRestorationRightPlaceholderControllerKey];
    }
    NSMutableArray *restorableViewControllers = [[NSMutableArray alloc] init];
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.restorationIdentifier.length)
        {
            [restorableViewControllers addObject:viewController];
        }
    }
    [coder encodeObject:restorableViewControllers forKey:kStateRestorationViewControllersKey];
    [coder encodeBool:(!!self.rightViewController.restorationIdentifier.length) forKey:kStateRestorationHadRestorableRightViewControllerKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    if ([coder containsValueForKey:kStateRestorationNavigationBarClassNameKey])
    {
        Class navigationBarClass = NSClassFromString([coder decodeObjectForKey:kStateRestorationNavigationBarClassNameKey]);
        if (navigationBarClass)
        {
            _navigationBarClass = navigationBarClass;
        }
    }
    if ([coder containsValueForKey:kStateRestorationToolbarClassNameKey])
    {
        Class toolbarClass = NSClassFromString([coder decodeObjectForKey:kStateRestorationToolbarClassNameKey]);
        if (toolbarClass)
        {
            _toolbarClass = toolbarClass;
        }
    }
    if ([coder containsValueForKey:kStateRestorationLeftToolbarKey])
    {
        self.leftToolbar = [coder decodeObjectForKey:kStateRestorationLeftToolbarKey];
    }
    if ([coder containsValueForKey:kStateRestorationRightToolbarKey])
    {
        self.rightToolbar = [coder decodeObjectForKey:kStateRestorationRightToolbarKey];
    }
    if ([coder containsValueForKey:kStateRestorationNavigationBarsHiddenKey])
    {
        self.navigationBarsHidden = [coder decodeBoolForKey:kStateRestorationNavigationBarsHiddenKey];
    }
    if ([coder containsValueForKey:kStateRestorationToolbarsHiddenKey])
    {
        self.toolbarsHidden = [coder decodeBoolForKey:kStateRestorationToolbarsHiddenKey];
    }
    if ([coder containsValueForKey:kStateRestorationLeftControllerWidthKey])
    {
        self.leftControllerWidth = [coder decodeFloatForKey:kStateRestorationLeftControllerWidthKey];
    }
    
    void (^addViewController)(UIViewController*, SGBDrillDownControllerPosition, SGBDrillDownControllerVisibility) = ^(UIViewController *viewController, SGBDrillDownControllerPosition position, SGBDrillDownControllerVisibility visibility) {
        [self addChildViewController:viewController];
        SGBDrillDownContainerView *containerView = [[SGBDrillDownContainerView alloc] init];
        [self.view addSubview:containerView];
        [containerView addViewToContentView:viewController.view];
        [self layoutController:viewController
                    atPosition:position
                    visibility:visibility];
    };
    if ([coder containsValueForKey:kStateRestorationLeftPlaceholderControllerKey])
    {
        self.leftPlaceholderController = [coder decodeObjectForKey:kStateRestorationLeftPlaceholderControllerKey];
        if (self.leftPlaceholderController)
        {
            addViewController(self.leftPlaceholderController, SGBDrillDownControllerPositionLeft, SGBDrillDownControllerVisibilityShowing);
        }
    }
    if ([coder containsValueForKey:kStateRestorationRightPlaceholderControllerKey])
    {
        self.rightPlaceholderController = [coder decodeObjectForKey:kStateRestorationRightPlaceholderControllerKey];
        if (self.rightPlaceholderController)
        {
            addViewController(self.rightPlaceholderController, SGBDrillDownControllerPositionRight, SGBDrillDownControllerVisibilityShowing);
        }
    }
    if ([coder containsValueForKey:kStateRestorationViewControllersKey])
    {
        NSMutableArray *viewControllers = [coder decodeObjectForKey:kStateRestorationViewControllersKey];
        UIViewController *rightViewController = nil;
        if (viewControllers.count >= 2 && [coder decodeBoolForKey:kStateRestorationHadRestorableRightViewControllerKey])
        {
            rightViewController = [viewControllers lastObject];
            [viewControllers removeLastObject];
        }
        self.leftViewControllers = viewControllers;
        for (NSUInteger i = 0, count = viewControllers.count, top = count - 1; i < count; ++i)
        {
            UIViewController *viewController = viewControllers[i];
            if (i == top)
            {
                addViewController(viewController, SGBDrillDownControllerPositionLeft, SGBDrillDownControllerVisibilityShowing);
            }
            else
            {
                addViewController(viewController, SGBDrillDownControllerPositionLeft, SGBDrillDownControllerVisibilityOffscreenLeft);
            }
        }
        [self.leftNavigationBar setItems:[self.leftViewControllers valueForKey:@"navigationItem"] animated:NO];
        if (rightViewController)
        {
            self.rightViewController = rightViewController;
            addViewController(self.rightViewController, SGBDrillDownControllerPositionRight, SGBDrillDownControllerVisibilityShowing);
            [self.rightNavigationBar setItems:@[self.rightViewController.navigationItem] animated:NO];
        }
    }
}

#pragma mark - KVO

// This duplicates UINavigationController's behaviour whereby it will pop to the root if the tab
// bar button is tapped. With thanks to rdelmar at http://stackoverflow.com/a/16488929/15371

- (void)stopKVOObservingParent
{
    if (self.kvoObservedTabBarController)
    {
        NSLog(@"%p de-observing %p", (id)self, (id)self.kvoObservedTabBarController);
        
        [self removeObserver:self forKeyPath:kSGBTabBarControllerSelectedViewControllerKeyPath context:nil];
        
        NSMutableDictionary *kvoObservers = objc_getAssociatedObject(self.kvoObservedTabBarController, kSGBTabBarControllerKVOObserversKey);
        kvoObservers[self.kvoObserverUUID] = nil;
        
        self.kvoObservedTabBarController = nil;
    }
}

- (void)startKVOObservingParent
{
    [self stopKVOObservingParent];
    
    if ([self.parentViewController isKindOfClass:[UITabBarController class]])
    {
        self.kvoObservedTabBarController = (UITabBarController *)self.parentViewController;
        NSLog(@"%p observing %p", (id)self, (id)self.kvoObservedTabBarController);
        
        SGBDrillDownContainerAssociatedObject *associatedObject = [[SGBDrillDownContainerAssociatedObject alloc] init];
        associatedObject.drillDownController = self;
        
        NSMutableDictionary *kvoObservers = objc_getAssociatedObject(self.kvoObservedTabBarController, kSGBTabBarControllerKVOObserversKey);
        if (!kvoObservers)
        {
            kvoObservers = [NSMutableDictionary dictionary];
            objc_setAssociatedObject(self.kvoObservedTabBarController, kSGBTabBarControllerKVOObserversKey, kvoObservers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        kvoObservers[self.kvoObserverUUID] = associatedObject;
        
        [self addObserver:self forKeyPath:kSGBTabBarControllerSelectedViewControllerKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:kSGBTabBarControllerSelectedViewControllerKeyPath] && [change[@"old"] isEqual:change[@"new"]] && [change[@"new"] isEqual:self])
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
    
    [self animate:animated withDuration:UINavigationControllerHideShowBarDuration animations:^{
        
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
    
    [self animate:animated withDuration:UINavigationControllerHideShowBarDuration animations:^{
        
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

- (UIScrollView *)scrollView
{
    return (UIScrollView *)self.view;
}

- (void)loadView
{
    self.view = [[UIScrollView alloc] init];
    
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

- (void)viewDidLoad
{
#ifdef __IPHONE_7_0
    // Protect against running iOS7+ SDK compiled code on iOS6 and below...
    if (NSClassFromString(@"UIScreenEdgePanGestureRecognizer"))
    {
        UIScreenEdgePanGestureRecognizer *swipeBackGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc]
                                                                        initWithTarget:self
                                                                        action:@selector(swipeBackGestureRecognizerStateChanged:)];
        swipeBackGestureRecognizer.edges = UIRectEdgeLeft;
        swipeBackGestureRecognizer.minimumNumberOfTouches = 1;
        swipeBackGestureRecognizer.maximumNumberOfTouches = 1;
        swipeBackGestureRecognizer.delegate = self;
        self.swipeBackGestureRecognizer = swipeBackGestureRecognizer;
    }
#endif
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

#pragma mark - Parent view controller

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    [super willMoveToParentViewController:parent];
    
    if (!parent)
    {
        [self stopKVOObservingParent];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent)
    {
        [self startKVOObservingParent];
    }
    
    [super didMoveToParentViewController:parent];
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.animatingRotation = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.animatingRotation = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#ifdef __IPHONE_7_0
- (BOOL)shouldAutorotate
{
    return (!self.swipeBackGestureRecognizer || (self.swipeBackGestureRecognizer.state == UIGestureRecognizerStatePossible));
}
#endif

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Layout

- (void)layoutNavigationBar:(UINavigationBar *)navigationBar imageView:(UIImageView *)imageView atPosition:(SGBDrillDownControllerPosition)position
{
    CGFloat top = 0;
    
    CGFloat navigationBarHeight = 44;
    if ((self.navigationBarPosition == UIBarPositionTopAttached) && !ON_LEGACY_UI)
    {
        navigationBarHeight = 64;
    }
    
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
    CGFloat top = self.view.bounds.size.height - (self.scrollView.contentInset.top + self.scrollView.contentInset.bottom);
    
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
    
    SGBDrillDownChildControllerLayout layout = [self layoutForController:controller
                                                              atPosition:position
                                                              visibility:visibility];
    
    if (!CGRectIsEmpty(layout.containerViewFrame) || !CGRectIsEmpty(layout.controllerViewFrame))
    {
        controller.view.frame = layout.controllerViewFrame;
        controller.view.drillDownContainerView.frame = layout.containerViewFrame;
        
        if ([controller.view respondsToSelector:@selector(setContentInset:)])
        {
            [(id)controller.view setContentInset:layout.contentInset];
        }
    }
}

- (SGBDrillDownChildControllerLayout)layoutForController:(UIViewController *)controller
                                              atPosition:(SGBDrillDownControllerPosition)position
                                              visibility:(SGBDrillDownControllerVisibility)visibility
{
    if (!controller) return (SGBDrillDownChildControllerLayout){CGRectZero, CGRectZero};
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    CGFloat top = -contentInset.top;
    
    if (!self.navigationBarsHidden)
    {
        CGFloat navigationBarHeight = 44;
        if ((self.navigationBarPosition == UIBarPositionTopAttached) && !ON_LEGACY_UI)
        {
            navigationBarHeight = 64;
        }
        
        if (self.leftNavigationBar.translucent && self.rightNavigationBar.translucent && [controller respondsToSelector:@selector(edgesForExtendedLayout)] && (controller.edgesForExtendedLayout & UIRectEdgeTop))
        {
            contentInset.top += navigationBarHeight;
        }
        else
        {
            top += navigationBarHeight;
            height -= navigationBarHeight;
        }
    }
    
    if (!self.toolbarsHidden)
    {
        CGFloat toolbarHeight = 44;
        
        if (self.leftToolbar.translucent && self.rightToolbar.translucent && [controller respondsToSelector:@selector(edgesForExtendedLayout)] && (controller.edgesForExtendedLayout & UIRectEdgeBottom))
        {
            contentInset.bottom += toolbarHeight;
        }
        else
        {
            height -= toolbarHeight;
        }
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
    
    CGRect containerRect = CGRectMake(containerLeft, top, containerWidth, height);
    CGRect controllerRect = CGRectMake(viewLeft, 0, viewWidth, containerRect.size.height);
    
    return (SGBDrillDownChildControllerLayout){
        containerRect,
        controllerRect,
        contentInset
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

#pragma mark - Gestures

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return !self.animatingRotation;
}

#ifdef __IPHONE_7_0
- (void)swipeBackGestureRecognizerStateChanged:(UIScreenEdgePanGestureRecognizer *)recognizer
{
    static CGRect previousLeftContainerStartFrame;
    static CGRect previousLeftContainerInitialParallaxFrame;
    static CGAffineTransform previousLeftContainerTransform;
    static CGRect leftContainerStartFrame;
    static CGRect leftControllerStartFrame;
    static CGPoint startLocation;
    static SGBDrillDownChildControllerLayout rightLayout;
    
    UIView *leftControllerView = self.leftViewController.view;
    SGBDrillDownContainerView *leftControllerContainerView = leftControllerView.drillDownContainerView;
    UIViewController *previousLeftViewController = (self.leftViewControllers.count > 1 ? self.leftViewControllers[self.leftViewControllers.count - 2] : self.leftPlaceholderController);
    SGBDrillDownContainerView *previousLeftControllerContainerView = previousLeftViewController.view.drillDownContainerView;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.suspendLayout = YES;
            
            rightLayout = [self layoutForController:self.leftViewController
                                         atPosition:SGBDrillDownControllerPositionRight
                                         visibility:SGBDrillDownControllerVisibilityShowing];
            
            startLocation = [recognizer locationInView:self.view];
            previousLeftContainerStartFrame = previousLeftControllerContainerView.frame;
            leftContainerStartFrame = leftControllerContainerView.frame;
            leftControllerStartFrame = leftControllerView.frame;
            previousLeftContainerTransform = previousLeftControllerContainerView.transform;
            
            [self layoutController:previousLeftViewController
                        atPosition:SGBDrillDownControllerPositionLeft
                        visibility:SGBDrillDownControllerVisibilityShowing];
            previousLeftContainerInitialParallaxFrame = SGBDrillDownControllerLeftParallaxFrame(leftContainerStartFrame);
            previousLeftControllerContainerView.frame = previousLeftContainerInitialParallaxFrame;
            [previousLeftControllerContainerView addFadingView];
            [previousLeftControllerContainerView setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
            previousLeftControllerContainerView.hidden = NO;
            
            [leftControllerContainerView addShadowViewAtPosition:SGBDrillDownContainerShadowBoth];
            
            UIViewController *rightViewController = (self.rightViewController ? self.rightViewController : self.rightPlaceholderController);
            [self.view insertSubview:rightViewController.view.drillDownContainerView belowSubview:leftControllerContainerView];
            [self.view insertSubview:previousLeftControllerContainerView belowSubview:leftControllerContainerView];
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint currentLocation = [recognizer locationInView:self.view];
            CGFloat dx = fmaxf(0.0, fminf(self.leftControllerWidth, (currentLocation.x - startLocation.x)));
            CGFloat openPercentage = (dx / self.leftControllerWidth);
            CGFloat additionalWidth = openPercentage * (rightLayout.containerViewFrame.size.width - self.leftControllerWidth);
            
            CGRect leftControllerContainerFrame = CGRectOffset(leftContainerStartFrame, dx, 0.0);
            leftControllerContainerFrame.size.width = self.leftControllerWidth + additionalWidth;
            leftControllerContainerView.frame =  leftControllerContainerFrame;
            
            CGRect leftControllerFrame = leftControllerStartFrame;
            leftControllerFrame.size.width += additionalWidth;
            leftControllerView.frame = leftControllerFrame;
            
            previousLeftControllerContainerView.transform = SGBDrillDownControllerLeftParallaxTransform(self.leftControllerWidth, 0.0, dx, previousLeftControllerContainerView.transform);
            
            CGFloat fadeAlpha = (1.0 - openPercentage) * kSGBDrillDownControllerHidingMaxFadingViewAlpha;
            [previousLeftControllerContainerView setFadingViewAlpha:fadeAlpha];
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGRect transformedPreviousLeftContainerFrame = CGRectApplyAffineTransform(previousLeftContainerInitialParallaxFrame, previousLeftControllerContainerView.transform);
            previousLeftControllerContainerView.transform = previousLeftContainerTransform;
            previousLeftControllerContainerView.frame = transformedPreviousLeftContainerFrame;
            
            CGPoint currentLocation = [recognizer locationInView:self.view];
            CGFloat dx = fmaxf(0.0, fminf(self.leftControllerWidth, (currentLocation.x - startLocation.x)));
            CGFloat openPercentage = (dx / self.leftControllerWidth);
            CGFloat currentVelocity = [recognizer velocityInView:self.view].x;
            if (fabsf(currentVelocity) > 500.0 || currentLocation.x > (self.leftControllerWidth * 0.66))
            {
                [self popViewControllerAnimated:YES
                              animationDuration:(kSGBDrillDownControllerAnimationDuration * (1.0 - openPercentage))
                          isSwipeInteractivePop:YES
                           additionalAnimations:nil
                                     completion:^{
                                         // We don't allow rotation while swiping...so trigger it if necessary after we're done.
                                         [UIViewController attemptRotationToDeviceOrientation];
                                     }];
            }
            else
            {
                [self animate:YES withDuration:(kSGBDrillDownControllerAnimationDuration * (1.0 - openPercentage))
                   animations:^{
                       leftControllerContainerView.frame = leftContainerStartFrame;
                       leftControllerView.frame = leftControllerStartFrame;
                       previousLeftControllerContainerView.frame = previousLeftContainerStartFrame;
                   }
                   completion:^(BOOL finished) {
                       self.suspendLayout = NO;
                       previousLeftControllerContainerView.hidden = YES;
                       [previousLeftControllerContainerView removeFadingView];
                       [leftControllerContainerView removeShadowView];
                       
                       // We don't allow rotation while swiping...so trigger it if necessary after we're done.
                       [UIViewController attemptRotationToDeviceOrientation];
                   }];
            }
            
            break;
        }
        default:
            break;
    }
}
#endif

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

- (void)configureLeftViewControllerForSwipeNavigation
{
    if (self.leftViewControllers.count >= 2 && self.swipeBackGestureRecognizer)
    {
        UIView* leftControllerContainerView = self.leftViewController.view.drillDownContainerView;
        [self.swipeBackGestureRecognizer.view removeGestureRecognizer:self.swipeBackGestureRecognizer];
        [leftControllerContainerView addGestureRecognizer:self.swipeBackGestureRecognizer];
    }
}

- (void)animate:(BOOL)animated withDuration:(NSTimeInterval)duration animations:(void(^)(void))animations completion:(void (^)(BOOL))completion
{
    if (animated)
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
    }
    
    UIViewController *oldLeftController = self.leftViewController;
    SGBDrillDownContainerView *oldLeftContainerView = nil;
    UIViewController *oldRightController = self.rightViewController;
    SGBDrillDownContainerView *oldRightContainerView = nil;
    
    // While because of our precondition check that early-returns from this method
    // if you attempt to push a nil view controller when the right view controller
    // is already nil we can assume here that viewController is implicitly not-nil
    // for the following two conditions, we check it explicitly for the sake of
    // LLVM's analyzer so that it knows for sure that later one we aren't potentially
    // breaking APIs by attempting to add a nil viewController to an array.
    BOOL pushingLeftController = viewController && (self.viewControllers.count == 0);
    BOOL pushingNewRightController = viewController && ((self.viewControllers.count > 0) && (self.rightViewController == nil));
    
    // We use fake items to cause navigation bar animations when necessary.
    UINavigationItem *rightFakeItem = SGBDrillDownControllerCreateFakeNavigationItem();
    UINavigationItem *leftFakeItem = SGBDrillDownControllerCreateFakeNavigationItem();
    
    UIBarButtonItem *emptyBackBarButtonItem = nil;
    
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
        
        UINavigationItem *leftNavigationItem = viewController.navigationItem;
        leftNavigationItem.hidesBackButton = YES;
        
        if (animated)
        {
            [self.leftNavigationBar setItems:@[ leftNavigationItem, leftFakeItem ] animated:NO];
            [self.leftNavigationBar setItems:@[ leftNavigationItem ] animated:YES];
        }
        else
        {
            [self.leftNavigationBar setItems:@[ leftNavigationItem ] animated:NO];
        }
        
        if (!leftNavigationItem.backBarButtonItem)
        {
            // I'm so, so sorry. iOS 7.1 shows a random ellipsis in place of the back button on the first pop unless I do this.
            emptyBackBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            leftNavigationItem.backBarButtonItem = emptyBackBarButtonItem;
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
        
        UINavigationItem* rightNavigationItem = viewController.navigationItem;
        rightNavigationItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ rightFakeItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ rightFakeItem, rightNavigationItem ] animated:animated];
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
        
        UINavigationItem *rightNavigationItem = viewController.navigationItem;
        rightNavigationItem.hidesBackButton = YES;
        UINavigationItem *oldRightNavigationItem = oldRightController.navigationItem;
        if (viewController)
        {
            if (oldRightNavigationItem.title)
            {
                rightFakeItem.title = oldRightNavigationItem.title;
            }
            [self.rightNavigationBar setItems:@[ rightFakeItem ] animated:NO];
            [self.rightNavigationBar setItems:@[ rightFakeItem, rightNavigationItem ] animated:animated];
        }
        
        NSArray *leftNavigationItems = [self.leftViewControllers valueForKey:@"navigationItem"];
        ((UINavigationItem *)[leftNavigationItems lastObject]).hidesBackButton = NO;
        [self.leftNavigationBar setItems:leftNavigationItems animated:animated];
    }
    
    if (pushingLeftController)
    {
        
        if (ON_LEGACY_UI)
        {
            self.leftNavigationBar.alpha = 0;
            self.leftToolbar.alpha = 0;
        }
        
        self.leftToolbar.items = viewController.toolbarItems;
    }
    else
    {
        if (ON_LEGACY_UI)
        {
            self.rightNavigationBar.alpha = 0;
            self.rightToolbar.alpha = 0;
        }
        
        self.rightToolbar.items = viewController.toolbarItems;
        
        if (!pushingNewRightController)
        {
            
            if (ON_LEGACY_UI)
            {
                self.leftNavigationBar.alpha = 0;
                self.leftToolbar.alpha = 0;
            }
            
            self.leftToolbar.items = [self.leftViewController toolbarItems];
        }
    }
    
    [self bringBarsToFront];
    
    [self animate:animated withDuration:kSGBDrillDownControllerAnimationDuration
       animations:^{
           [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillPushNotification object:self];
           
           if (ON_LEGACY_UI)
           {
               if (!pushingLeftController)
               {
                   self.rightNavigationBar.alpha = 1;
                   self.rightToolbar.alpha = 1;
               }
               
               if (!pushingNewRightController)
               {
                   self.leftNavigationBar.alpha = 1;
                   self.leftToolbar.alpha = 1;
               }
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
               
               if (emptyBackBarButtonItem && self.leftViewController.navigationItem.backBarButtonItem == emptyBackBarButtonItem)
               {
                   self.leftViewController.navigationItem.backBarButtonItem = nil;
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
               
               if (viewController)
               {
                   [viewControllerContainer removeShadowView];
                   [viewControllerContainer removeFadingView];
               }
               else if (self.rightPlaceholderController)
               {
                   [self.rightPlaceholderController endAppearanceTransition];
                   SGBDrillDownContainerView *rightPlaceholderView = self.rightPlaceholderController.view.drillDownContainerView;
                   [rightPlaceholderView removeFadingView];
               }
               
               rightFakeItem.title = @"";
           }
           
           if (viewController)
           {
               [viewController didMoveToParentViewController:self];
           }
           
           [self configureLeftViewControllerForSwipeNavigation];
           
           if (completion) completion();
           
           [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerDidPushNotification object:self];
       }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    return [self popViewControllerAnimated:animated
                         animationDuration:kSGBDrillDownControllerAnimationDuration
                     isSwipeInteractivePop:NO
                      additionalAnimations:nil
                                completion:completion];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
                              animationDuration:(NSTimeInterval)animationDuration
                          isSwipeInteractivePop:(BOOL)isSwipeInteractivePop
                           additionalAnimations:(void (^)(void))additionalAnimations
                                     completion:(void (^)(void))completion
{
    if (self.viewControllers.count < 1) return nil;
    
    if (ON_LEGACY_UI)
    {
        // Snapshot the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
        self.leftNavigationImageView.image = [self imageForView:self.leftNavigationBar];
        self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
        self.leftToolbarImageView.image = [self imageForView:self.leftToolbar];
        self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    }
    
    UIViewController *poppedViewController = nil;
    
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
    
    // We use fake items to cause navigation bar animations when necessary.
    UINavigationItem *rightFakeItem = SGBDrillDownControllerCreateFakeNavigationItem();
    UINavigationItem *leftFakeItem = SGBDrillDownControllerCreateFakeNavigationItem();
    
    UIBarButtonItem *emptyBackBarButtonItem = nil;
    
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
        
        [self.leftNavigationBar setItems:@[ lastViewController.navigationItem ] animated:NO];
        [self.leftNavigationBar setItems:@[ lastViewController.navigationItem, leftFakeItem ] animated:animated];
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
        
        secondToLastViewController.navigationItem.hidesBackButton = YES;
        [self.rightNavigationBar setItems:@[ rightFakeItem, secondToLastViewController.navigationItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ rightFakeItem ] animated:animated];
    }
    else
    {
        newLeftController = self.leftViewControllers[self.leftViewControllers.count - 2];
        [newLeftController beginAppearanceTransition:YES animated:animated];
        
        newLeftContainer = newLeftController.view.drillDownContainerView;
        if (!isSwipeInteractivePop)
        {
            [self layoutController:newLeftController
                        atPosition:SGBDrillDownControllerPositionLeft
                        visibility:SGBDrillDownControllerVisibilityShowing];
            
            
            newLeftContainer.frame = SGBDrillDownControllerLeftParallaxFrame(newLeftContainer.frame);
            [newLeftContainer addFadingView];
            [newLeftContainer setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
            newLeftContainer.hidden = NO;
        }
        
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
        
        NSArray *leftNavigationItems = [self.leftViewControllers valueForKey:@"navigationItem"];
        ((UINavigationItem *)leftNavigationItems[0]).hidesBackButton = NO;
        [self.leftNavigationBar setItems:leftNavigationItems animated:animated];
        
        UINavigationItem *oldRightNavigationItem;
        if (oldRightController)
        {
            oldRightNavigationItem = oldRightController.navigationItem;
            oldRightNavigationItem.hidesBackButton = YES;
        }
        else
        {
            oldRightNavigationItem = rightFakeItem;
        }
        UINavigationItem *rightNavigationItem = newRightController.navigationItem;
        rightNavigationItem.hidesBackButton = YES;
        
        if (!rightNavigationItem.backBarButtonItem)
        {
            // I'm so, so sorry. iOS 7.1 shows a random ellipsis in place of the back button on the first pop unless I do this.
            emptyBackBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            rightNavigationItem.backBarButtonItem = emptyBackBarButtonItem;
        }
        
        [self.rightNavigationBar setItems:@[ rightNavigationItem, oldRightNavigationItem ] animated:NO];
        [self.rightNavigationBar setItems:@[ rightNavigationItem ] animated:animated];
    }
    
    [poppedViewController beginAppearanceTransition:NO animated:animated];
    
    if (!poppingSecondLastController)
    {
        if (ON_LEGACY_UI)
        {
            self.leftNavigationBar.alpha = 0;
            self.leftToolbar.alpha = 0;
        }
        
        self.leftToolbar.items = newLeftController.toolbarItems;
    }
    
    if (!poppingLastController)
    {
        if (ON_LEGACY_UI)
        {
            self.rightNavigationBar.alpha = 0;
            self.rightToolbar.alpha = 0;
        }
        
        self.rightToolbar.items = newRightController.toolbarItems;
    }
    
    [self bringBarsToFront];
    
    [self animate:animated withDuration:animationDuration
       animations:^{
           [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillPopNotification object:self];
           
           if (ON_LEGACY_UI)
           {
               if (!poppingSecondLastController)
               {
                   self.leftNavigationBar.alpha = 1;
                   self.leftToolbar.alpha = 1;
               }
               
               if (!poppingLastController)
               {
                   self.rightNavigationBar.alpha = 1;
                   self.rightToolbar.alpha = 1;
               }
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
               
               if (emptyBackBarButtonItem && self.rightViewController.navigationItem.backBarButtonItem == emptyBackBarButtonItem)
               {
                   self.rightViewController.navigationItem.backBarButtonItem = nil;
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
               
               [self configureLeftViewControllerForSwipeNavigation];
           }
           
           [poppedViewController.view.drillDownContainerView removeFromSuperview];
           [poppedViewController.view removeFromSuperview];
           [poppedViewController endAppearanceTransition];
           [poppedViewController removeFromParentViewController];
           
           if (completion) completion();
           
           [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerDidPopNotification object:self];
       }];
    
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
                      animationDuration:kSGBDrillDownControllerAnimationDuration
                  isSwipeInteractivePop:NO
                   additionalAnimations:^{
                       [self layoutController:leftViewController
                                   atPosition:SGBDrillDownControllerPositionLeft
                                   visibility:SGBDrillDownControllerVisibilityOffscreenLeft];
                   }
                             completion:^{
                                 for (UIViewController *intermediateViewController in intermediaryLeftViewControllers)
                                 {
                                     [intermediateViewController.view.drillDownContainerView removeFromSuperview];
                                     [intermediateViewController.view removeFromSuperview];
                                     [intermediateViewController endAppearanceTransition];
                                     [intermediateViewController removeFromParentViewController];
                                 }
                                 [leftViewContainer removeShadowView];
                                 [leftViewContainer removeFromSuperview];
                                 [leftViewController.view removeFromSuperview];
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
    [self replaceRightViewController:viewController
                            animated:animated
                       animationType:SGBDrillDownControllerReplaceAnimationTypeFade
                          completion:completion];
}

- (void)replaceRightViewController:(UIViewController *)viewController animated:(BOOL)animated animationType:(SGBDrillDownControllerReplaceAnimationType) animationType completion:(void (^)(void))completion
{
    if (!self.leftViewController) [NSException raise:SGBDrillDownControllerException format:@"Cannot replace right controller without a left controller"];
    
    if (viewController == self.rightViewController)
    {
        // Nothing to do
        if (completion) completion();
        return;
    }
    
    if (viewController && [self.viewControllers containsObject:viewController]) [NSException raise:SGBDrillDownControllerException format:@"Cannot replace with a controller that is already in the stack"];
    
    // Snap the existing controllers so we can do fades. This forces layout, so we have to do it before we start.
    self.rightNavigationImageView.image = [self imageForView:self.rightNavigationBar];
    self.rightToolbarImageView.image = [self imageForView:self.rightToolbar];
    
    UIViewController *oldRightController = self.rightViewController;
    if (oldRightController)
    {
        self.rightViewController = nil;
    }
    else
    {
        oldRightController = self.rightPlaceholderController;
        [oldRightController beginAppearanceTransition:NO animated:animated];
    }
    
    UIViewController *newRightController;
    if (viewController)
    {
        newRightController = viewController;
        self.rightViewController = viewController;
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
    
    switch (animationType) {
        case SGBDrillDownControllerReplaceAnimationTypeFade:
            [self.rightNavigationBar setItems:[NSArray arrayWithObjects:newRightController.navigationItem, nil] animated:NO];
            if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 0;
            
            self.rightToolbar.items = newRightController.toolbarItems;
            if (ON_LEGACY_UI) self.rightToolbar.alpha = 0;
            
            // We'll fade the new controller in on the right
            [self layoutController:newRightController atPosition:SGBDrillDownControllerPositionRight visibility:SGBDrillDownControllerVisibilityShowing];
            newRightController.view.drillDownContainerView.alpha = 0;
            
            break;
            
        case SGBDrillDownControllerReplaceAnimationTypePush:
            [self.rightNavigationBar setItems:[NSArray arrayWithObjects:newRightController.navigationItem, nil] animated:animated];
            if (ON_LEGACY_UI) self.rightNavigationBar.alpha = 0;
            
            self.rightToolbar.items = newRightController.toolbarItems;
            if (ON_LEGACY_UI) self.rightToolbar.alpha = 0;
            
            [self layoutController:newRightController
                        atPosition:SGBDrillDownControllerPositionRight
                        visibility:SGBDrillDownControllerVisibilityOffscreenRight];
            [newRightController.view.drillDownContainerView addShadowViewAtPosition:SGBDrillDownContainerShadowLeft];
            SGBDrillDownContainerView *oldRightContainerView = oldRightController.view.drillDownContainerView;
            [oldRightContainerView addFadingView];
            [oldRightContainerView setFadingViewAlpha:0.0];
            [self.view insertSubview:oldRightContainerView belowSubview:self.leftViewController.view.drillDownContainerView];
            
            break;
    }
    
    [self bringBarsToFront];
    
    [self animate:animated withDuration:kSGBDrillDownControllerAnimationDuration
       animations:^{
           
           [[NSNotificationCenter defaultCenter] postNotificationName:SGBDrillDownControllerWillReplaceNotification object:self];
           
           switch (animationType) {
               case SGBDrillDownControllerReplaceAnimationTypeFade:
                   if (ON_LEGACY_UI)
                   {
                       self.rightNavigationBar.alpha = 1;
                       self.rightToolbar.alpha = 1;
                   }
                   
                   oldRightController.view.drillDownContainerView.alpha = 0;
                   newRightController.view.drillDownContainerView.alpha = 1;
                   
                   break;
                   
               case SGBDrillDownControllerReplaceAnimationTypePush:
                   [self layoutController:newRightController
                               atPosition:SGBDrillDownControllerPositionRight
                               visibility:SGBDrillDownControllerVisibilityShowing];
                   
                   SGBDrillDownContainerView *oldRightContainerView = oldRightController.view.drillDownContainerView;
                   oldRightContainerView.frame = SGBDrillDownControllerLeftParallaxFrame(oldRightContainerView.frame);
                   [oldRightContainerView setFadingViewAlpha:kSGBDrillDownControllerHidingMaxFadingViewAlpha];
                   
                   break;
           }
       }
       completion:^(BOOL finished) {
           switch (animationType) {
               case SGBDrillDownControllerReplaceAnimationTypeFade:
                   break;
                   
               case SGBDrillDownControllerReplaceAnimationTypePush:
                   [newRightController.view.drillDownContainerView removeShadowView];
                   break;
           }
           
           if (newRightController == self.rightPlaceholderController)
           {
               [newRightController endAppearanceTransition];
           }
           
           if (oldRightController == self.rightPlaceholderController)
           {
               [self layoutController:oldRightController
                           atPosition:SGBDrillDownControllerPositionLeft
                           visibility:SGBDrillDownControllerVisibilityHiddenLeft];
               oldRightController.view.drillDownContainerView.hidden = YES;
               [oldRightController endAppearanceTransition];
           }
           else
           {
               [oldRightController.view.drillDownContainerView removeFromSuperview];
               [oldRightController.view removeFromSuperview];
               [oldRightController removeFromParentViewController];
           }
           
           if (viewController)
           {
               [viewController didMoveToParentViewController:self];
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
    if ((bar == self.leftNavigationBar) || (bar == self.rightNavigationBar)) return self.navigationBarPosition;
    if ((bar == self.leftToolbar) || (bar == self.rightToolbar)) return self.toolbarPosition;
    return UIBarPositionAny;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    [self popViewControllerAnimated:YES completion:nil];
    return NO;
}

@end

@implementation SGBDrillDownContainerAssociatedObject

- (void)dealloc
{
    [self.drillDownController stopKVOObservingParent];
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
