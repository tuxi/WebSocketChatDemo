//
//  XYApiClient.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYDialog.h"
#import "XYMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYApiClientResponse : NSObject

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger next;
@property (nonatomic, assign) NSInteger previous;
@property (nonatomic, strong) NSArray *results;

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(Class)rsClass;

@end

@interface XYApiClient : NSObject

// 获取我的对话列表
+ (NSURLSessionDataTask *)getMyDialogsWithCompletionHandler:(void (^ _Nullable )(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
