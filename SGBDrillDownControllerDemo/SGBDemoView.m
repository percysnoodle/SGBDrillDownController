//
// SGBDemoView.m.h
// 
// Created on 2013-02-23 using NibFree
// 

#import "SGBDemoView.h"

@interface SGBDemoView ()

@property (nonatomic, strong) UIButton *pushButton;
@property (nonatomic, strong) UIButton *popButton;
@property (nonatomic, strong) UIButton *navigationBarsButton;
@property (nonatomic, strong) UIButton *toolbarsButton;

@end

@implementation SGBDemoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = YES;
        
        _pushButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _pushButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_pushButton setTitle:@"Push!" forState:UIControlStateNormal];
        [_pushButton addTarget:self action:@selector(pushButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pushButton];
        
        _popButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _popButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_popButton setTitle:@"Pop!" forState:UIControlStateNormal];
        [_popButton addTarget:self action:@selector(popButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_popButton];
        
        _navigationBarsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _navigationBarsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_navigationBarsButton setTitle:@"Toggle navigation bars!" forState:UIControlStateNormal];
        [_navigationBarsButton addTarget:self action:@selector(navigationBarsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_navigationBarsButton];
        
        _toolbarsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _toolbarsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_toolbarsButton setTitle:@"Toggle toolbars!" forState:UIControlStateNormal];
        [_toolbarsButton addTarget:self action:@selector(toolbarsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_toolbarsButton];
    }
    return self;
}

- (void)layoutSubviews
{
    _pushButton.frame = CGRectMake(20, 20, self.bounds.size.width - 40, 44);
    _popButton.frame = CGRectMake(20, 72, self.bounds.size.width - 40, 44);
    _navigationBarsButton.frame = CGRectMake(20, 124, self.bounds.size.width - 40, 44);
    _toolbarsButton.frame = CGRectMake(20, 176, self.bounds.size.width - 40, 44);
}

- (void)pushButtonTapped:(id)sender
{
    [self.delegate demoViewPushButtonTapped:self];
}

- (void)popButtonTapped:(id)sender
{
    [self.delegate demoViewPopButtonTapped:self];
}

- (void)navigationBarsButtonTapped:(id)sender
{
    [self.delegate demoViewNavigationBarsButtonTapped:self];
}

- (void)toolbarsButtonTapped:(id)sender
{
    [self.delegate demoViewToolbarsButtonTapped:self];
}

@end

