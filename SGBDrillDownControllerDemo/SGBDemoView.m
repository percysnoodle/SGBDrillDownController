//
// SGBDemoView.m.h
// 
// Created on 2013-02-23 using NibFree
// 

#import "SGBDemoView.h"

@interface SGBDemoView ()

@property (nonatomic, strong) UIButton *pushButton;
@property (nonatomic, strong) UIButton *popButton;

@end

@implementation SGBDemoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = YES;
        self.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
        
        _pushButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_pushButton setTitle:@"Push!" forState:UIControlStateNormal];
        [_pushButton addTarget:self action:@selector(pushButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pushButton];
        
        _popButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_popButton setTitle:@"Pop!" forState:UIControlStateNormal];
        [_popButton addTarget:self action:@selector(popButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_popButton];
    }
    return self;
}

- (void)layoutSubviews
{
    _pushButton.frame = CGRectMake(20, 20, self.bounds.size.width - 40, 44);
    _popButton.frame = CGRectMake(20, 72, self.bounds.size.width - 40, 44);
}

- (void)pushButtonTapped:(id)sender
{
    [self.delegate demoViewPushButtonTapped:self];
}

- (void)popButtonTapped:(id)sender
{
    [self.delegate demoViewPopButtonTapped:self];
}

@end

