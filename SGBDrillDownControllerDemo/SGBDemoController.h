//
// SGBDemoController.h.h
// 
// Created on 2013-02-23 using NibFree
// 

#import <UIKit/UIKit.h>


@interface SGBDemoController : UIViewController <UIViewControllerRestoration>

@property (nonatomic, assign) NSInteger number;
- (id)initWithNumber:(NSInteger)number;

@end

