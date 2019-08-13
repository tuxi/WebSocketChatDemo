//
//  XYLoginViewController.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XYLoginViewStyle) {
    XYLoginViewStyleLogin,
    XYLoginViewStyleRegister,
    XYLoginViewStyleForget,
    XYLoginViewStyleChangePassword,
};

FOUNDATION_EXPORT NSNotificationName const kLoginSuccessNotification;


@interface XYLoginViewController : UIViewController

+ (instancetype)sharedInstance;

// 显示登陆控制器
// @param style 登陆控制器的view样式
// @parma superVC 登陆控制器的父控制器
- (void)showWithStyle:(XYLoginViewStyle)style animated:(BOOL)animated closeable:(BOOL)closeable superController:(UIViewController *)superVC;

@end

NS_ASSUME_NONNULL_END
