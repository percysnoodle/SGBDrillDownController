//
//  SGBDrillDownContainerView.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 11/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownContainerView.h"

@implementation SGBDrillDownContainerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = NO;
        
        _leftBorderView = [[UIView alloc] init];
        _leftBorderView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _leftBorderView.opaque = YES;
        _leftBorderView.backgroundColor = [UIColor blackColor];
        [self addSubview:_leftBorderView];
        
        _rightBorderView = [[UIView alloc] init];
        _rightBorderView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
        _rightBorderView.opaque = YES;
        _rightBorderView.backgroundColor = [UIColor blackColor];
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
    [self.contentView addSubview:view];
}

- (void)layoutSubviews
{
    CGRect frame = self.bounds;
    
    self.contentView.frame = frame;
    self.leftBorderView.frame = CGRectMake(-1, 0, 1, frame.size.height);
    self.rightBorderView.frame = CGRectMake(frame.size.width, 0, 1, frame.size.height);
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

