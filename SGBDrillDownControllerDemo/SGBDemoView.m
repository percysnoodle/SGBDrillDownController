//
// SGBDemoView.m.h
// 
// Created on 2013-02-23 using NibFree
// 

#import "SGBDemoView.h"

@interface SGBDemoView ()

@property (nonatomic, strong) UILabel *appearanceCountLabel;
@property (nonatomic, strong) UISwitch *animationSwitch;

@property (nonatomic, strong) UIButton *pushButton;
@property (nonatomic, strong) UIButton *pushNilButton;
@property (nonatomic, strong) UIButton *popButton;
@property (nonatomic, strong) UIButton *popToRootButton;
@property (nonatomic, strong) UIButton *navigationBarsButton;
@property (nonatomic, strong) UIButton *toolbarsButton;
@property (nonatomic, strong) UIButton *replaceButton;
@property (nonatomic, strong) UIButton *removeButton;
@property (nonatomic, strong) UIButton *toggleBackgroundAlphaButton;

// To support KIF tests.
@property (nonatomic, strong) UILabel *screenNumberLabel;

@end

@implementation SGBDemoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = YES;
        self.alwaysBounceVertical = YES;
        
        _appearanceCountLabel = [[UILabel alloc] init];
        _appearanceCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _appearanceCountLabel.backgroundColor = [UIColor clearColor];
        _appearanceCountLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        _appearanceCountLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_appearanceCountLabel];
        [self updateAppearanceCountLabel];
        
        _animationSwitch = [[UISwitch alloc] init];
        _animationSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_animationSwitch addTarget:self action:@selector(animationSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_animationSwitch];
        
        _pushButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _pushButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_pushButton setTitle:@"Push!" forState:UIControlStateNormal];
        [_pushButton addTarget:self action:@selector(pushButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pushButton];
        
        _pushNilButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _pushNilButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_pushNilButton setTitle:@"Push nil!" forState:UIControlStateNormal];
        [_pushNilButton addTarget:self action:@selector(pushNilButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_pushNilButton];
        
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

        _toggleBackgroundAlphaButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _toggleBackgroundAlphaButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_toggleBackgroundAlphaButton setTitle:@"Toggle Background Alpha" forState:UIControlStateNormal];
        [_toggleBackgroundAlphaButton addTarget:self action:@selector(toggleBackgroundAlphaButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_toggleBackgroundAlphaButton];

        _screenNumberLabel = [[UILabel alloc] init];
        _screenNumberLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _screenNumberLabel.backgroundColor = [UIColor clearColor];
        _screenNumberLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        _screenNumberLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_screenNumberLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    self.appearanceCountLabel.frame = CGRectMake(20, 20, self.bounds.size.width - 140, 44);
    self.animationSwitch.frame = CGRectMake(self.bounds.size.width - 101, 28, 79, 27);
    
    self.pushButton.frame = CGRectMake(20, 72, self.bounds.size.width - 40, 44);
    self.pushNilButton.frame = CGRectMake(20, 124, self.bounds.size.width - 40, 44);
    self.popButton.frame = CGRectMake(20, 176, self.bounds.size.width - 40, 44);
    self.popToRootButton.frame = CGRectMake(20, 228, self.bounds.size.width - 40, 44);
    self.navigationBarsButton.frame = CGRectMake(20, 280, self.bounds.size.width - 40, 44);
    self.toolbarsButton.frame = CGRectMake(20, 332, self.bounds.size.width - 40, 44);
    self.replaceButton.frame = CGRectMake(20, 384, self.bounds.size.width - 40, 44);
    self.removeButton.frame = CGRectMake(20, 436, self.bounds.size.width - 40, 44);
    self.toggleBackgroundAlphaButton.frame = CGRectMake(20, 488, self.bounds.size.width - 40, 44);

    self.screenNumberLabel.frame = CGRectMake(20, self.bounds.size.height - 40, self.bounds.size.width - 40, 20);
}

- (void)setScreenNumber:(NSInteger)number
{
    self.screenNumberLabel.text = [NSString stringWithFormat:@"Screen %d View", number];
    self.screenNumberLabel.accessibilityLabel = [NSString stringWithFormat:@"Screen %d View", number];
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

- (BOOL)animationSwitchOn
{
    return self.animationSwitch.on;
}

- (void)setAnimationSwitchOn:(BOOL)animationSwitchOn
{
    self.animationSwitch.on = animationSwitchOn;
}

- (void)animationSwitchChanged:(id)sender
{
    [self.delegate demoViewAnimationSwitchChanged:self];
}

- (void)pushButtonTapped:(id)sender
{
    [self.delegate demoViewPushButtonTapped:self];
}

- (void)pushNilButtonTapped:(id)sender
{
    [self.delegate demoViewPushNilButtonTapped:self];
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

- (void)toggleBackgroundAlphaButtonTapped:(id)sender
{
  [self.delegate demoViewToggleBackgroundAlphaButtonTapped:self];
}

@end

