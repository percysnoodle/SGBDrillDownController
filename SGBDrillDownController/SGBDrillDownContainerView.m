//
//  SGBDrillDownContainerView.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 11/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownContainerView.h"

#define ON_LEGACY_UI ([[[UIDevice currentDevice] systemVersion] integerValue] < 7)

static const CGFloat kSGBDrillDownContainerTransitionShadowRadius = 5.0;

@interface SGBDrillDownContainerView ()

@property (weak, nonatomic) UIImageView *shadowView;
@property (weak, nonatomic) UIView *fadingView;
@property (assign, nonatomic) SGBDrillDownContainerShadow shadowPosition;

@end

@implementation SGBDrillDownContainerView

@synthesize borderBackgroundColor=_borderBackgroundColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIColor *borderColor = self.borderBackgroundColor;

        _leftBorderView = [[UIView alloc] init];
        _leftBorderView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _leftBorderView.opaque = YES;
        _leftBorderView.backgroundColor = borderColor;
        [self addSubview:_leftBorderView];
        
        _rightBorderView = [[UIView alloc] init];
        _rightBorderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        _rightBorderView.opaque = YES;
        _rightBorderView.backgroundColor = borderColor;
        [self addSubview:_rightBorderView];
        
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _contentView.clipsToBounds = YES;
        [self addSubview:_contentView];
    }
    return self;
}

- (void)addViewToContentView:(UIView *)view
{
    view.autoresizingMask = UIViewAutoresizingNone;
    [self.contentView addSubview:view];
}

- (void)layoutSubviews
{
    CGRect frame = self.bounds;
    
    self.contentView.frame = frame;
    self.leftBorderView.frame = CGRectMake(-1, 0, 1, frame.size.height);
    self.rightBorderView.frame = CGRectMake(frame.size.width, 0, 1, frame.size.height);
}

// on iOS 7, the center and bounds keep getting messed up by _applyISEngineLayoutValues
// but since we only ever set the frame, we can stop it by killing setCenter and setBounds.
- (void)setCenter:(CGPoint)center { return; }
- (void)setBounds:(CGRect)bounds { return; }

- (UIColor *)borderBackgroundColor
{
    if (_borderBackgroundColor)
    {
        return _borderBackgroundColor;
    }
    else
    {
        return ON_LEGACY_UI ? [UIColor blackColor] : [UIColor lightGrayColor];
    }
}

- (void)setBorderBackgroundColor:(UIColor *)borderBackgroundColor
{
     _borderBackgroundColor = borderBackgroundColor;
    self.leftBorderView.backgroundColor = borderBackgroundColor;
    self.rightBorderView.backgroundColor = borderBackgroundColor;
}

- (UIImage *)shadowImageForPosition:(SGBDrillDownContainerShadow)position
{
    static UIImage *shadowImageBoth;
    static UIImage *shadowImageLeft;
    static UIImage *shadowImageRight;

    UIImage * __strong *shadowImageRef = nil;
    switch (position)
    {
        case SGBDrillDownContainerShadowNone:
            return nil;
        case SGBDrillDownContainerShadowBoth:
            shadowImageRef = &shadowImageBoth;
            break;
        case SGBDrillDownContainerShadowLeft:
            shadowImageRef = &shadowImageLeft;
            break;
        case SGBDrillDownContainerShadowRight:
            shadowImageRef = &shadowImageRight;
            break;
    }

    if (!(*shadowImageRef))
    {
        UIGraphicsBeginImageContext(CGSizeMake(1.0 + (kSGBDrillDownContainerTransitionShadowRadius * 2.0), 1.0));
        CGContextRef c = UIGraphicsGetCurrentContext();

        CGFloat locations[2] = {0.0, 1.0};
        NSArray *colors = @[(id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor,
                            (id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,];
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (CFArrayRef)colors, locations);

        switch (position)
        {
            case SGBDrillDownContainerShadowNone:
                break;
            case SGBDrillDownContainerShadowBoth:
                CGContextDrawLinearGradient(c, gradient, CGPointMake(0.0, 0.0), CGPointMake(kSGBDrillDownContainerTransitionShadowRadius, 0.0), 0);
                CGContextDrawLinearGradient(c, gradient, CGPointMake(1.0 + 2.0 * kSGBDrillDownContainerTransitionShadowRadius, 0.0), CGPointMake(kSGBDrillDownContainerTransitionShadowRadius + 1.0, 0.0), 0);
                break;
            case SGBDrillDownContainerShadowLeft:
                CGContextDrawLinearGradient(c, gradient, CGPointMake(0.0, 0.0), CGPointMake(kSGBDrillDownContainerTransitionShadowRadius, 0.0), 0);
                break;
            case SGBDrillDownContainerShadowRight:
                CGContextDrawLinearGradient(c, gradient, CGPointMake(1.0 + 2.0 * kSGBDrillDownContainerTransitionShadowRadius, 0.0), CGPointMake(kSGBDrillDownContainerTransitionShadowRadius + 1.0, 0.0), 0);
                break;
        }

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorspace);

        *shadowImageRef = [image resizableImageWithCapInsets:UIEdgeInsetsMake(1.0, kSGBDrillDownContainerTransitionShadowRadius, 1.0, kSGBDrillDownContainerTransitionShadowRadius)];
    }
    return *shadowImageRef;
}

- (void)addShadowViewAtPosition:(SGBDrillDownContainerShadow)position;
{

    if (!self.shadowView)
    {
        UIImageView *shadowView = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, -kSGBDrillDownContainerTransitionShadowRadius, 0.0)];
        shadowView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        self.shadowView = shadowView;
        [self addSubview:shadowView];
    }
    if (self.shadowPosition != position)
    {
        self.shadowView.image = [self shadowImageForPosition:position];
        self.shadowPosition = position;
    }
}

- (void)removeShadowView
{
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
    self.shadowPosition = SGBDrillDownContainerShadowNone;
}

- (void)setShadowViewAlpha:(CGFloat)alpha
{
    self.shadowView.alpha = alpha;
}

- (void)addFadingView
{
    if (!self.fadingView)
    {
        UIView *fadingView = [[UIView alloc] initWithFrame:self.bounds];
        fadingView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        fadingView.backgroundColor = [UIColor blackColor];
        self.fadingView = fadingView;
        [self addSubview:fadingView];
    }
}

- (void)removeFadingView
{
    [self.fadingView removeFromSuperview];
    self.fadingView = nil;
}

- (void)setFadingViewAlpha:(CGFloat)alpha
{
    self.fadingView.alpha = alpha;
}

@end

@implementation UIView (SGBDrillDownContainerView)

- (SGBDrillDownContainerView *)drillDownContainerView
{
    for (UIView *view = self.superview; view; view = view.superview)
    {
        if ([view isKindOfClass:[SGBDrillDownContainerView class]]) return (SGBDrillDownContainerView *)view;
    }
    
    return nil;
}

@end

