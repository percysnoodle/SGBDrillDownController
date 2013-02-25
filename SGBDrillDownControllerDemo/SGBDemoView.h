//
// SGBDemoView.h.h
// 
// Created on 2013-02-23 using NibFree
// 

#import <UIKit/UIKit.h>

@protocol SGBDemoViewDelegate;

@interface SGBDemoView : UIView

@property (nonatomic, weak) id<SGBDemoViewDelegate> delegate;

@end

@protocol SGBDemoViewDelegate <NSObject>

- (void)demoViewPushButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewPopButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewNavigationBarsButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewToolbarsButtonTapped:(SGBDemoView *)demoView;

@end

