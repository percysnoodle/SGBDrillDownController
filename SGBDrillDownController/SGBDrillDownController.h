//
//  SGBDrillDownController.h
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SGBDrillDownControllerReplaceAnimationType)
{
    SGBDrillDownControllerReplaceAnimationTypeFade=0,
    SGBDrillDownControllerReplaceAnimationTypePush,
};

extern NSString * const SGBDrillDownControllerException;
extern NSString * const SGBDrillDownControllerWillPushNotification;
extern NSString * const SGBDrillDownControllerDidPushNotification;
extern NSString * const SGBDrillDownControllerWillPopNotification;
extern NSString * const SGBDrillDownControllerDidPopNotification;
extern NSString * const SGBDrillDownControllerWillReplaceNotification;
extern NSString * const SGBDrillDownControllerDidReplaceNotification;

@interface SGBDrillDownController : UIViewController <UIGestureRecognizerDelegate, UIViewControllerRestoration>

@property (nonatomic, assign, readonly) Class navigationBarClass;
@property (nonatomic, assign, readonly) Class toolbarClass;
- (id)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass;

@property (nonatomic, strong, readonly) UINavigationBar *leftNavigationBar;
@property (nonatomic, strong, readonly) UINavigationBar *rightNavigationBar;
@property (nonatomic, assign) BOOL navigationBarsHidden;
- (void)setNavigationBarsHidden:(BOOL)navigationBarsHidden animated:(BOOL)animated;

@property (nonatomic, assign) UIBarPosition navigationBarPosition;
@property (nonatomic, assign) BOOL propagatesNavigationItem;

@property (nonatomic, strong, readonly) UIToolbar *leftToolbar;
@property (nonatomic, strong, readonly) UIToolbar *rightToolbar;
@property (nonatomic, assign) BOOL toolbarsHidden;
- (void)setToolbarsHidden:(BOOL)toolbarsHidden animated:(BOOL)animated;

@property (nonatomic, assign) UIBarPosition toolbarPosition;
@property (nonatomic, assign) BOOL propagatesTabBarItem;

// Navigation stack behaviour
@property (nonatomic, strong, readonly) NSArray *viewControllers;
@property (nonatomic, strong, readonly) UIViewController *leftViewController;
@property (nonatomic, strong, readonly) UIViewController *rightViewController;
@property (nonatomic, strong) UIViewController *leftPlaceholderController;
@property (nonatomic, strong) UIViewController *rightPlaceholderController;

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void(^)(void))completion;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void(^)(void))completion;
- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)popToRootViewControllerAnimated:(BOOL)animated completion:(void(^)(void))completion;

// Split behaviour
- (void)replaceRightViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)replaceRightViewController:(UIViewController *)viewController animated:(BOOL)animated animationType:(SGBDrillDownControllerReplaceAnimationType) animationType completion:(void (^)(void))completion;

- (void)showRightViewController:(UIViewController *)rightViewController forLeftViewController:(UIViewController *)leftViewController animated:(BOOL)animated completion:(void(^)(void))completion;

@property (nonatomic, assign) CGFloat leftControllerWidth;

@end

@interface UIViewController (SGBDrillDownController)

@property (nonatomic, strong, readonly) SGBDrillDownController *drillDownController;

@end