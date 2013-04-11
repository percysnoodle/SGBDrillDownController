//
// SGBDemoController.h.h
// 
// Created on 2013-02-23 using NibFree
// 

#import <UIKit/UIKit.h>

@protocol SGBDemoControllerDelegate;

@interface SGBDemoController : UIViewController

@property (nonatomic, assign, readonly) NSInteger number;
- (id)initWithNumber:(NSInteger)number;

@property (nonatomic, weak) id<SGBDemoControllerDelegate> delegate;

@end

@protocol SGBDemoControllerDelegate <NSObject>

- (void)demoControllerDidRequestPush:(SGBDemoController *)demoController;
- (void)demoControllerDidRequestPop:(SGBDemoController *)demoController;
- (void)demoControllerDidRequestPopToRoot:(SGBDemoController *)demoController;
- (void)demoControllerDidRequestToggleNavigationBars:(SGBDemoController *)demoController;
- (void)demoControllerDidRequestToggleToolbars:(SGBDemoController *)demoController;

@end