//
// SGBDemoView.m.h
// 
// Created on 2013-02-23 using NibFree
// 

#import "SGBDemoView.h"

@interface SGBDemoView ()

@property (nonatomic, strong) UILabel *appearanceCountLabel;
@property (nonatomic, strong) UIButton *pushButton;
@property (nonatomic, strong) UIButton *popButton;
@property (nonatomic, strong) UIButton *popToRootButton;
@property (nonatomic, strong) UIButton *navigationBarsButton;
@property (nonatomic, strong) UIButton *toolbarsButton;
@property (nonatomic, strong) UIButton *replaceButton;
@property (nonatomic, strong) UIButton *removeButton;

@end

@implementation SGBDemoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = YES;
        
        _appearanceCountLabel = [[UILabel alloc] init];
        _appearanceCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _appearanceCountLabel.backgroundColor = [UIColor clearColor];
        _appearanceCountLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        _appearanceCountLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_appearanceCountLabel];
        [self updateAppearanceCountLabel];
        
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
        
        _popToRootButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _popToRootButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_popToRootButton setTitle:@"Pop to root!" forState:UIControlStateNormal];
        [_popToRootButton addTarget:self action:@selector(popToRootButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_popToRootButton];
        
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
        
        _replaceButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _replaceButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_replaceButton setTitle:@"Replace!" forState:UIControlStateNormal];
        [_replaceButton addTarget:self action:@selector(replaceButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_replaceButton];
        
        _removeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _removeButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_removeButton setTitle:@"Remove!" forState:UIControlStateNormal];
        [_removeButton addTarget:self action:@selector(removeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_removeButton];
    }
    return self;
}

- (void)layoutSubviews
{
    self.appearanceCountLabel.frame = CGRectMake(20, 20, self.bounds.size.width - 40, 44);
    self.pushButton.frame = CGRectMake(20, 72, self.bounds.size.width - 40, 44);
    self.popButton.frame = CGRectMake(20, 124, self.bounds.size.width - 40, 44);
    self.popToRootButton.frame = CGRectMake(20, 176, self.bounds.size.width - 40, 44);
    self.navigationBarsButton.frame = CGRectMake(20, 228, self.bounds.size.width - 40, 44);
    self.toolbarsButton.frame = CGRectMake(20, 280, self.bounds.size.width - 40, 44);
    self.replaceButton.frame = CGRectMake(20, 332, self.bounds.size.width - 40, 44);
    self.removeButton.frame = CGRectMake(20, 384, self.bounds.size.width - 40, 44);
}

- (void)setWillAppearCount:(NSInteger)willAppearCount
{
    _willAppearCount = willAppearCount;
    [self updateAppearanceCountLabel];
}

- (void)setDidAppearCount:(NSInteger)didAppearCount
{
    _didAppearCount = didAppearCount;
    [self updateAppearanceCountLabel];
}

- (void)updateAppearanceCountLabel
{
    self.appearanceCountLabel.text = [NSString stringWithFormat:@"Will appear: %d, Did appear: %d", self.willAppearCount, self.didAppearCount];
}

- (void)pushButtonTapped:(id)sender
{
    [self.delegate demoViewPushButtonTapped:self];
}

- (void)popButtonTapped:(id)sender
{
    [self.delegate demoViewPopButtonTapped:self];
}

- (void)popToRootButtonTapped:(id)sender
{
    [self.delegate demoViewPopToRootButtonTapped:self];
}

- (void)navigationBarsButtonTapped:(id)sender
{
    [self.delegate demoViewNavigationBarsButtonTapped:self];
}

- (void)toolbarsButtonTapped:(id)sender
{
    [self.delegate demoViewToolbarsButtonTapped:self];
}

- (void)replaceButtonTapped:(id)sender
{
    [self.delegate demoViewReplaceButtonTapped:self];
}

- (void)removeButtonTapped:(id)sender
{
    [self.delegate demoViewRemoveButtonTapped:self];
}

@end

