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

+ (NSURLSessionDataTask *)loginWithMobile:(NSString *)mobile
                                 password:(NSString *)password
                        completionHandler:(void (^ _Nullable )(NSURLSessionDataTask * _Nonnull task, XYUser * _Nullable user, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
