//
//  SGBDrillDownContainerView.h
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 11/04/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGBDrillDownContainerView : UIView

@property (nonatomic, strong, readonly) UIView *leftBorderView;
@property (nonatomic, strong, readonly) UIView *rightBorderView;
@property (nonatomic, strong, readonly) UIView *contentView;

- (void)addViewToContentView:(UIView *)view;

@end

@interface UIView (SGBDrillDownContainerView)

@property (nonatomic, strong, readonly) SGBDrillDownContainerView *drillDownContainerView;

@end