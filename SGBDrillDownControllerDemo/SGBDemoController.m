//
// SGBDemoController.m.h
// 
// Created on 2013-02-23 using NibFree
// 

#import "SGBDemoController.h"
#import "SGBDemoView.h"
#import "SGBDrillDownController.h"

@interface SGBDemoController () <SGBDemoViewDelegate>

@property (nonatomic, strong, readonly) SGBDemoView *demoView;
@property (nonatomic, assign) NSInteger willAppearCount;
@property (nonatomic, assign) NSInteger didAppearCount;
@property (nonatomic, assign) BOOL useAnimation;
@property (nonatomic, assign) BOOL backgroundHasAlpha;

@end

@implementation SGBDemoController

static NSString * const kStateRestorationIdentifierPrefix = @"SGBDemoController";
+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    UIViewController *viewController = [[self alloc ] initWithNumber:0];
    viewController.restorationIdentifier = [identifierComponents lastObject];
    return viewController;
}

- (id)initWithNumber:(NSInteger)number
{
    self = [super init];
    if (self)
    {
        self.restorationClass = self.class;
        self.restorationIdentifier = [NSString stringWithFormat:@"%@-%i", kStateRestorationIdentifierPrefix, number];

        self.number = number;
        
        _useAnimation = YES;
        
        self.toolbarItems = @[
                              
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(requestPop)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            [[UIBarButtonItem alloc] initWithTitle:self.title style:UIBarButtonItemStylePlain target:nil action:nil],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(requestPush)]
            
        ];
    }
    return self;
}

static NSString * const kStateRestorationNumberKey = @"number";
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeInteger:self.number forKey:kStateRestorationNumberKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    if ([coder containsValueForKey:kStateRestorationNumberKey])
    {
        self.number = [coder decodeIntegerForKey:kStateRestorationNumberKey];
    }
}

- (void)loadView
{
    self.view = [[SGBDemoView  alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [self updateBackgroundColor];
    [self.demoView setScreenNumber:self.number];
    self.demoView.delegate = self;
    self.demoView.animationSwitchOn = self.useAnimation;
}

- (UIColor *)backgroundColor
{
    UIColor *baseColor = [UIColor brownColor];
    if (self.number > 0)
    {
        switch (self.number % 7)
        {
            case 1: baseColor = [UIColor redColor]; break;
            case 2: baseColor = [UIColor orangeColor]; break;
            case 3: baseColor = [UIColor yellowColor]; break;
            case 4: baseColor = [UIColor greenColor]; break;
            case 5: baseColor = [UIColor cyanColor]; break;
            case 6: baseColor = [UIColor blueColor]; break;
            case 0: baseColor = [UIColor purpleColor]; break;
        }
    }

    return (self.backgroundHasAlpha ? [baseColor colorWithAlphaComponent:0.5] : baseColor);
}

- (void) updateBackgroundColor
{
    self.view.backgroundColor = [self backgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.willAppearCount++;
    self.demoView.willAppearCount = self.willAppearCount;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.didAppearCount++;
    self.demoView.didAppearCount = self.didAppearCount;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.willAppearCount--;
    self.demoView.willAppearCount = self.willAppearCount;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.didAppearCount--;
    self.demoView.didAppearCount = self.didAppearCount;
}

- (void)setNumber:(NSInteger)number
{
    _number = number;
    self.title = [NSString stringWithFormat:@"Screen %d", number];
    if (self.isViewLoaded)
    {
        [self updateBackgroundColor];
        [self.demoView setScreenNumber:number];
    }
}

- (SGBDemoView *)demoView
{
    return (SGBDemoView *)self.view;
}

- (void)demoViewAnimationSwitchChanged:(SGBDemoView *)demoView
{
    self.useAnimation = demoView.animationSwitchOn;
}

- (void)demoViewPushButtonTapped:(SGBDemoView *)demoView
{
    [self requestPush];
}

- (void)demoViewPushNilButtonTapped:(SGBDemoView *)demoView
{
    [self requestPushNil];
}

- (void)demoViewPopButtonTapped:(SGBDemoView *)demoView
{
    [self requestPop];
}

- (void)demoViewPopToRootButtonTapped:(SGBDemoView *)demoView
{
    [self requestPopToRoot];
}

- (void)demoViewNavigationBarsButtonTapped:(SGBDemoView *)demoView
{
    [self requestToggleNavigationBars];
}

- (void)demoViewToolbarsButtonTapped:(SGBDemoView *)demoView
{
    [self requestToggleToolbars];
}

- (void)demoViewReplaceButtonTapped:(SGBDemoView *)demoView
{
    [self requestReplacement];
}

- (void)demoViewRemoveButtonTapped:(SGBDemoView *)demoView
{
    [self requestRemoval];
}

- (void)demoViewToggleBackgroundAlphaButtonTapped:(SGBDemoView *)demoView
{
  [self requestToggleBackgroundAlpha];
}

- (void)requestPush
{
    SGBDemoController *topController = [[self.drillDownController viewControllers] lastObject];
    SGBDemoController *nextController = [[SGBDemoController alloc] initWithNumber:topController.number + 1];
    nextController.useAnimation = self.useAnimation;
    if (topController)
    {
        nextController.backgroundHasAlpha = topController.backgroundHasAlpha;
        [nextController updateBackgroundColor];
    }

    [self.drillDownController pushViewController:nextController animated:self.useAnimation completion:nil];
}

- (void)requestPushNil
{
    [self.drillDownController pushViewController:nil animated:self.useAnimation completion:nil];
}

- (void)requestPop
{
    [self.drillDownController popViewControllerAnimated:self.useAnimation completion:nil];
}

- (void)requestPopToRoot
{
    [self.drillDownController popToRootViewControllerAnimated:self.useAnimation completion:nil];
}

- (void)requestToggleNavigationBars
{
    [self.drillDownController setNavigationBarsHidden:!self.drillDownController.navigationBarsHidden animated:self.useAnimation];
}

- (void)requestToggleToolbars
{
    [self.drillDownController setToolbarsHidden:!self.drillDownController.toolbarsHidden animated:self.useAnimation];
}

- (void)requestReplacement
{
    if (self.drillDownController.leftViewController)
    {
        SGBDemoController *topController = [[self.drillDownController viewControllers] lastObject];
        SGBDemoController *nextController = [[SGBDemoController alloc] initWithNumber:topController.number + 1];
        nextController.useAnimation = self.useAnimation;
        [self.drillDownController replaceRightViewController:nextController animated:self.useAnimation completion:nil];
    }
}

- (void)requestRemoval
{
    if (self.drillDownController.leftViewController)
    {
        [self.drillDownController replaceRightViewController:nil animated:self.useAnimation completion:nil];
    }
}

- (void)requestToggleBackgroundAlpha
{
  NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithArray:self.drillDownController.viewControllers];
  if (self.drillDownController.leftPlaceholderController)
  {
    [viewControllers addObject:self.drillDownController.leftPlaceholderController];
  }
  if (self.drillDownController.rightPlaceholderController)
  {
    [viewControllers addObject:self.drillDownController.rightPlaceholderController];
  }
  for (UIViewController *viewController in viewControllers)
  {
    if ([viewController isKindOfClass:[SGBDemoController class]])
    {
      SGBDemoController *demoController = (SGBDemoController *)viewController;
      demoController.backgroundHasAlpha = !demoController.backgroundHasAlpha;
      [demoController updateBackgroundColor];
    }
  }
}

@end

@implementation UITabBarController (SGBAutorotationFixes)

- (BOOL)shouldAutorotate {
  return [self.selectedViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
  return [self.selectedViewController supportedInterfaceOrientations];
}

@end

