//
//  XYAuthenticationManager.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYAuthenticationManager : NSObject

// 用于接口请求的授权
@property (nonatomic, copy, nullable) NSString *authToken;
// 记录当前登陆的用户
@property (nonatomic, strong, nullable) XYUser *user;
// 是否登陆
@property (nonatomic, assign, readonly) BOOL isLogin;

+ (instancetype)manager;

// 让登陆状态无效，退出登陆时需要调用此方法
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
