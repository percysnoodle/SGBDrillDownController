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

@end

@implementation SGBDemoController

- (id)initWithNumber:(NSInteger)number
{
    self = [super init];
    if (self)
    {
        _number = number;
        self.title = [NSString stringWithFormat:@"Screen %d", number];
        
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
}

- (SGBDemoView *)demoView
{
    return (SGBDemoView *)self.view;
}

- (void)demoViewPushButtonTapped:(SGBDemoView *)demoView
{
    [self requestPush];
}

- (void)demoViewPopButtonTapped:(SGBDemoView *)demoView
{
    [self requestPop];
}

- (void)demoViewNavigationBarsButtonTapped:(SGBDemoView *)demoView
{
    [self requestToggleNavigationBars];
}

- (void)demoViewToolbarsButtonTapped:(SGBDemoView *)demoView
{
    [self requestToggleToolbars];
}

- (void)requestPush
{
    [self.delegate demoControllerDidRequestPush:self];
}

- (void)requestPop
{
    [self.delegate demoControllerDidRequestPop:self];
}

- (void)requestToggleNavigationBars
{
    [self.delegate demoControllerDidRequestToggleNavigationBars:self];
}

- (void)requestToggleToolbars
{
    [self.delegate demoControllerDidRequestToggleToolbars:self];
}

@end

