//
// SGBDemoView.h.h
// 
// Created on 2013-02-23 using NibFree
// 

#import <UIKit/UIKit.h>

@protocol SGBDemoViewDelegate;

@interface SGBDemoView : UIScrollView

@property (nonatomic, weak) id<SGBDemoViewDelegate> delegate;
@property (nonatomic, assign) NSInteger willAppearCount;
@property (nonatomic, assign) NSInteger didAppearCount;

@property (nonatomic, assign) BOOL animationSwitchOn;

- (void)setScreenNumber:(NSInteger)number;

@end

@protocol SGBDemoViewDelegate <NSObject>

- (void)demoViewAnimationSwitchChanged:(SGBDemoView *)demoView;
- (void)demoViewPushButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewPushNilButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewPopButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewPopToRootButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewNavigationBarsButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewToolbarsButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewReplaceButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewRemoveButtonTapped:(SGBDemoView *)demoView;
- (void)demoViewToggleBackgroundAlphaButtonTapped:(SGBDemoView *)demoView;

@end

