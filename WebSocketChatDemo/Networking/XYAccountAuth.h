//
//  XYAccountAuth.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYAccountAuth : NSObject

+ (NSURLSessionDataTask * _Nullable)loginWithMobile:(NSString *)mobile
                                 password:(NSString *)password
                        completionHandler:(void (^ _Nullable )(NSURLSessionDataTask * _Nullable task, XYUser * _Nullable user, NSError *_Nullable error))completion;

// 发送心跳包，校验登陆状态
// @param completion isValid 是否有效 如果登陆为YES
+ (NSURLSessionDataTask * _Nullable)heartbeatWithCompletionHandler:(void (^ _Nullable )(NSURLSessionDataTask * _Nullable task, BOOL isValid, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
