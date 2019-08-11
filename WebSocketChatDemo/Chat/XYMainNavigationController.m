//
//  XYMainNavigationController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYMainNavigationController.h"
#import "XYAuthenticationManager.h"
#import "XYLoginViewController.h"

@interface XYMainNavigationController ()

@end

@implementation XYMainNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    
    if ([XYAuthenticationManager manager].user == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[XYLoginViewController sharedInstance] showWithStyle:XYLoginViewStyleLogin animated:NO closeable:NO superController:viewController];
        });
    }
    
}



@end
