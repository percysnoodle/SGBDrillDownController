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

@end

@implementation SGBDemoController

- (id)initWithNumber:(NSInteger)number
{
    self = [super init];
    if (self)
    {
        _number = number;
        self.title = [NSString stringWithFormat:@"Screen %d", number];
        
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

- (void)loadView
{
    self.view = [[SGBDemoView  alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    
    UIColor *color = [[UIColor brownColor] colorWithAlphaComponent:0.5];
    
    if (self.number > 0) switch (self.number % 7)
    {
        case 1: color = [[UIColor redColor] colorWithAlphaComponent:0.5]; break;
        case 2: color = [[UIColor orangeColor] colorWithAlphaComponent:0.5]; break;
        case 3: color = [[UIColor yellowColor] colorWithAlphaComponent:0.5]; break;
        case 4: color = [[UIColor greenColor] colorWithAlphaComponent:0.5]; break;
        case 5: color = [[UIColor cyanColor] colorWithAlphaComponent:0.5]; break;
        case 6: color = [[UIColor blueColor] colorWithAlphaComponent:0.5]; break;
        case 0: color = [[UIColor purpleColor] colorWithAlphaComponent:0.5]; break;
            
    }
    
    self.view.backgroundColor = color;
    self.demoView.delegate = self;
    self.demoView.animationSwitchOn = self.useAnimation;
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

- (void)requestPush
{
    SGBDemoController *topController = [[self.drillDownController viewControllers] lastObject];
    SGBDemoController *nextController = [[SGBDemoController alloc] initWithNumber:topController.number + 1];
    nextController.useAnimation = self.useAnimation;
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

@end

