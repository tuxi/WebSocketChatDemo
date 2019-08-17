//
//  XYWebSocketClient.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 响应到的 socket 数据包类型
typedef NSString * XYSocketResponseType NS_STRING_ENUM;
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeKey;
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeGoneOnline; // 上线
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeGoneOffline; // 下线
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeNewMessage; // 新消息
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeUsersChanged; // 聊天室中当前活动用户的已连接客户端列表
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeOpponentTyping; // 对方正在输入中
FOUNDATION_EXPORT XYSocketResponseType const XYSocketResponseTypeOpponentReadMessage; // 对方消息已读回执

typedef NS_ENUM(NSInteger,XYSocketStatus) {
    XYSocketStatusConnected,// 已连接
    XYSocketStatusFailed,// 失败
    XYSocketStatusClosed,
};


@interface XYWebSocketClient : NSObject

// 超时重连时间，默认10秒
@property (nonatomic,assign) NSTimeInterval overtime;

// 重连次数,默认5次
@property (nonatomic, assign) NSUInteger maxReconnectCount;
// socket 连接状态
@property (nonatomic, assign) XYSocketStatus status;

// 开始与某个用户对话
- (void)openWithOpponent:(NSString *)username;

// 关闭连接
// 告诉对方我要下线了， 发送关闭连接的数据包
- (void)close;

// 给对方发送消息
// @param username 接收消息的用户
// @param message 消息内容
- (void)sendMessage:(NSString *)message;

// 接收到消息的回调
- (void)onReceiveMessageCallback:(void (^)(NSDictionary *message))callback;

// 检查对方是否在线
// @param opponent 发送用户名，因为用户需要知道对方是否在线
- (void)sendOnlineCheckPacket;

// 发送已读消息数据包
- (void)sendReadMessagePacketWithMessageId:(NSString *)messageId;

// 告诉对方我正在输入， 键盘在输入时，发送正在输入的数据包
- (void)sendTypingPacket;

@end

NS_ASSUME_NONNULL_END
