//
//  SGBDrillDownContainerView.h
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 11/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SGBDrillDownContainerShadow)
{
    SGBDrillDownContainerShadowNone=0,
    SGBDrillDownContainerShadowBoth,
    SGBDrillDownContainerShadowLeft,
    SGBDrillDownContainerShadowRight,
};

@interface SGBDrillDownContainerView : UIView

@property (nonatomic, strong) UIColor *borderBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong, readonly) UIView *leftBorderView;
@property (nonatomic, strong, readonly) UIView *rightBorderView;
@property (nonatomic, strong, readonly) UIView *contentView;

- (void)addViewToContentView:(UIView *)view;

- (void)addShadowViewAtPosition:(SGBDrillDownContainerShadow)position;
- (void)removeShadowView;
- (void)setShadowViewAlpha:(CGFloat)alpha;

- (void)addFadingView;
- (void)removeFadingView;
- (void)setFadingViewAlpha:(CGFloat)alpha;

@end

@interface UIView (SGBDrillDownContainerView)

@property (nonatomic, strong, readonly) SGBDrillDownContainerView *drillDownContainerView;

@end