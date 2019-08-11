//
//  XYWebSocketClient.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYWebSocketClient : NSObject

+ (instancetype)sharedInstance;

// socket连接
- (void)startWithHost:(NSURL *)host;

// 断开连接，此操作应由用户触发，不再出发重连机制
- (void)stop;

// 给某个用户发送消息
// @param username 接收消息的用户
// @param message 消息内容
- (void)sendMessageToOpponent:(NSString *)username message:(NSString *)message;

// 接收到消息的回调
- (void)onReceiveMessageCallback:(void (^)(id message))callback;

@end

NS_ASSUME_NONNULL_END
