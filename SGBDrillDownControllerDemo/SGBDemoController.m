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
    }
    return self;
}

- (void)loadView
{
    self.view = [[SGBDemoView  alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.demoView.delegate = self;
}

- (SGBDemoView *)demoView
{
    return (SGBDemoView *)self.view;
}

- (void)demoViewPushButtonTapped:(SGBDemoView *)demoView
{
    SGBDemoController *nextController = [[SGBDemoController alloc] initWithNumber:self.number + 1];
    [self.drillDownController pushViewController:nextController animated:YES completion:nil];
}

- (void)demoViewPopButtonTapped:(SGBDemoView *)demoView
{
    [self.drillDownController popViewControllerAnimated:YES completion:nil];
}

@end

