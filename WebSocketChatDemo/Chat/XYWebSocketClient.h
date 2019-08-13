//
//  XYWebSocketClient.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,XYSocketStatus){
    XYSocketStatusConnected,// 已连接
    XYSocketStatusFailed,// 失败
    XYSocketStatusClosedByServer,// 系统关闭
    XYSocketStatusClosedByUser,// 用户关闭
};

@interface XYWebSocketClient : NSObject

// 超时重连时间，默认10秒
@property (nonatomic,assign) NSTimeInterval overtime;

// 重连次数,默认5次
@property (nonatomic, assign) NSUInteger maxReconnectCount;
// socket 连接状态
@property (nonatomic, assign) XYSocketStatus status;

+ (instancetype)sharedInstance;

// 开始与某个用户对话
- (void)openWithOpponent:(NSString *)username;

// 告诉对方我要下线了， 发送关闭连接的数据包
// 断开连接，此操作应由用户触发，不再触发重连机制
- (void)close;

// 给对方发送消息
// @param username 接收消息的用户
// @param message 消息内容
- (void)sendMessage:(NSString *)message;

// 接收到消息的回调
//- (void)onReceiveMessageCallback:(void (^)(id message))callback;

// 检查对方是否在线
// @param opponent 发送用户名，因为用户需要知道对方是否在线
- (void)sendOnlineCheckPacket;

// 发送已读消息数据包
- (void)sendReadMessagePacketWithMessageId:(NSString *)messageId;

// 告诉对方我正在输入， 键盘在输入时，发送正在输入的数据包
- (void)sendTypingPacket;

@end

NS_ASSUME_NONNULL_END
