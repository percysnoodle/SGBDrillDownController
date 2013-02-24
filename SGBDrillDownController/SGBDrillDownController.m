//
//  SGBDrillDownController.m
//  SGBDrillDownControllerDemo
//
//  Created by Simon Booth on 23/02/2013.
//  Copyright (c) 2013 Simon Booth. All rights reserved.
//

#import "SGBDrillDownController.h"

@interface SGBDrillDownController () <UINavigationBarDelegate>

@property (nonatomic, strong, readwrite) NSArray *viewControllers;
@property (nonatomic, strong, readwrite) UINavigationBar *leftNavigationBar;
@property (nonatomic, strong, readwrite) UINavigationBar *rightNavigationBar;

@end

@implementation SGBDrillDownController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (id)init
{
    return [self initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
}

- (id)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _navigationBarClass = navigationBarClass;
        _toolbarClass = toolbarClass;
        _leftControllerWidth = 320;
        _viewControllers = [NSArray array];
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    self.leftNavigationBar = [[self.navigationBarClass alloc] init];
    self.leftNavigationBar.delegate = self;
    [self.view addSubview:self.leftNavigationBar];
    
    self.rightNavigationBar = [[self.navigationBarClass alloc] init];
    self.rightNavigationBar.delegate = self;
    [self.view addSubview:self.rightNavigationBar];
    
    [self.view setNeedsLayout];
}

- (void)viewDidUnload
{
    self.leftNavigationBar = nil;
    self.rightNavigationBar = nil;
}

- (void)viewDidLayoutSubviews
{
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    
    CGFloat leftWidth = self.leftControllerWidth;
    CGFloat rightWidth = width - leftWidth;
    
    CGFloat topHeight = 44;
    CGFloat bottomHeight = height - 44;
    
    self.leftNavigationBar.frame = CGRectMake(0, 0, leftWidth, topHeight);
    self.rightNavigationBar.frame = CGRectMake(leftWidth, 0, rightWidth, topHeight);
    
    for (UIViewController *viewController in self.viewControllers)
    {
        if (viewController == self.rightViewController)
        {
            viewController.view.frame = CGRectMake(leftWidth, topHeight, rightWidth, bottomHeight);
        }
        else if (viewController == self.leftViewController)
        {
            viewController.view.frame = CGRectMake(0, topHeight, leftWidth, bottomHeight);
        }
        else
        {
            viewController.view.frame = CGRectMake(-leftWidth, topHeight, leftWidth, bottomHeight);
        }
    }
}

- (UIViewController *)leftViewController
{
    NSUInteger viewControllerCount = self.viewControllers.count;
    if (viewControllerCount > 1) return [self.viewControllers objectAtIndex:(viewControllerCount - 2)];
    else return [self.viewControllers lastObject];
}

- (UIViewController *)rightViewController
{
    if (self.viewControllers.count > 1) return [self.viewControllers lastObject];
    else return nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (viewController == nil) return;
    
    if (self.viewControllers.count > 1)
    {
        [self.leftViewController viewWillDisappear:animated];
    }
    
    NSArray *oldNavigationItems = [self.viewControllers valueForKey:@"navigationItem"];
    
    self.viewControllers = [self.viewControllers arrayByAddingObject:viewController];
    
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    
    [self.view addSubview:viewController.view];
    
    if (self.viewControllers.count == 1)
    {
        viewController.view.frame = CGRectMake(self.view.bounds.size.width, 44, self.leftControllerWidth, self.view.bounds.size.height - 44);
        [viewController.view setNeedsLayout];
        [viewController.view layoutIfNeeded];
        
        [self.rightNavigationBar setItems:@[] animated:animated];
        [self.leftNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
    }
    else
    {
        viewController.view.frame = CGRectMake(self.view.bounds.size.width, 44, self.view.bounds.size.width - self.leftControllerWidth, self.view.bounds.size.height - 44);
        [viewController.view setNeedsLayout];
        [viewController.view layoutIfNeeded];
        
        [self.rightNavigationBar setItems:@[ viewController.navigationItem ] animated:animated];
        [self.leftNavigationBar setItems:oldNavigationItems animated:animated];
    }
    
    if (animated)
    {   
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
            [viewController didMoveToParentViewController:self];
            if (completion) completion();
            
        }];
    }
    else
    {
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        if (completion) completion();
    }
}


- (UIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (self.viewControllers.count <= 1) return nil;
    
    if (self.viewControllers.count > 2)
    {
        UIViewController *offscreenController = self.viewControllers[self.viewControllers.count - 3];
        [offscreenController viewWillAppear:animated];
    }
    
    UIViewController *poppedViewController = [self.viewControllers lastObject];
    self.viewControllers = [self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)];
    UIViewController *newLastViewController = [self.viewControllers lastObject];
    
    if (self.viewControllers.count == 0)
    {
        [self.leftNavigationBar setItems:@[] animated:animated];
        [self.rightNavigationBar setItems:@[] animated:animated];
    }
    else if (self.viewControllers.count == 1)
    {
        [self.leftNavigationBar setItems:@[ newLastViewController.navigationItem ] animated:animated];
        
        if (self.rightNavigationBar.items.count > 0)
        {
            // insert a fake item so that the navigation bar does a pop animation
            UINavigationItem *lastItem = [[UINavigationItem alloc] init];
            lastItem.hidesBackButton = YES;
            [self.rightNavigationBar setItems:@[lastItem] animated:NO];
        }
        
        [self.rightNavigationBar setItems:@[] animated:animated];
    }
    else
    {
        NSArray *newNavigationItems = (self.viewControllers.count > 0) ? [[self.viewControllers subarrayWithRange:NSMakeRange(0, self.viewControllers.count - 1)] valueForKey:@"navigationItem"] : @[];
        
        [self.leftNavigationBar setItems:newNavigationItems animated:animated];
        if (self.rightNavigationBar.items.count > 0)
        {
            // insert a fake item so that the navigation bar does a pop animation
            UINavigationItem *lastItem = [[UINavigationItem alloc] init];
            lastItem.hidesBackButton = YES;
            [self.rightNavigationBar setItems:@[ newLastViewController.navigationItem, lastItem ] animated:NO];
            [self.rightNavigationBar setItems:@[ newLastViewController.navigationItem ] animated:animated];
        }
        else
        {
            [self.rightNavigationBar setItems:@[ newLastViewController.navigationItem ] animated:animated];
        }
    }
    
    if (animated)
    {
        [poppedViewController willMoveToParentViewController:nil];
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
           
            poppedViewController.view.frame = CGRectMake(self.view.bounds.size.width, 44, poppedViewController.view.frame.size.width, self.view.bounds.size.height - 44);
           
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            
            [poppedViewController removeFromParentViewController];
            [poppedViewController.view removeFromSuperview];
            [poppedViewController didMoveToParentViewController:nil];
            
            if (completion) completion();
            
        }];
    }
    else
    {
        [poppedViewController willMoveToParentViewController:nil];
        [poppedViewController removeFromParentViewController];
        [poppedViewController.view removeFromSuperview];
        [poppedViewController didMoveToParentViewController:nil];
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        if (completion) completion();
    }
    
    return poppedViewController;
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    [self popViewControllerAnimated:YES completion:nil];
    return NO;
}

@end

@implementation UIViewController (SGBDrillDownController)

- (SGBDrillDownController *)drillDownController
{
    for (UIViewController *viewController = self.parentViewController; viewController != nil; viewController = viewController.parentViewController)
    {
        if ([viewController isKindOfClass:[SGBDrillDownController class]]) return (SGBDrillDownController *)viewController;
    }
    
    return nil;
}

@end

