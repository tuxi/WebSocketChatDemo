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

@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, strong) XYUser *user;
@property (nonatomic, assign, readonly) BOOL isLogin;

+ (instancetype)manager;

@end

NS_ASSUME_NONNULL_END
