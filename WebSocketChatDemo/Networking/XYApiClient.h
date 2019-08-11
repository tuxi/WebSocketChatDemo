//
//  XYApiClient.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYApiClientResponse.h"

NS_ASSUME_NONNULL_BEGIN


@interface XYApiClient : NSObject

// 获取我的对话列表
// @param page 从1开始
+ (NSURLSessionDataTask *)getMyDialogsWithPage:(NSInteger)page completionHandler:(void (^ _Nullable )(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
