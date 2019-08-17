//
//  XYWebSocketClient.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYWebSocketClient.h"
#import <SRWebSocket.h>
#import "XYAuthenticationManager.h"
#import "XYSafeTimer.h"

static void dispatch_main_async_safe(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

typedef NSString * XYSocketRequestType NS_STRING_ENUM;
/**
 发送socket的类型有以下7种
 */
static XYSocketRequestType const XYSocketRequestTypeNewMessage = @"new-message";
static XYSocketRequestType const XYSocketRequestTypeNewUser = @"new-user";
static XYSocketRequestType const XYSocketRequestTypeOnline = @"online";
static XYSocketRequestType const XYSocketRequestTypeOffline = @"offline";
static XYSocketRequestType const XYSocketRequestTypeCheckOnline = @"check-online";
static XYSocketRequestType const XYSocketRequestTypeIsTyping = @"is-typing";
static XYSocketRequestType const XYSocketRequestTypeReadMessage = @"read_message";

XYSocketResponseType const XYSocketResponseTypeKey = @"type";

/**
 接受到的socket类型
 */
XYSocketResponseType const XYSocketResponseTypeGoneOnline = @"gone-online"; // 上线
XYSocketResponseType const XYSocketResponseTypeGoneOffline = @"gone-offline"; // 下线
XYSocketResponseType const XYSocketResponseTypeNewMessage = @"new-message"; // 新消息
XYSocketResponseType const XYSocketResponseTypeUsersChanged = @"users-changed"; // 聊天室中当前活动用户的已连接客户端列表
XYSocketResponseType const XYSocketResponseTypeOpponentTyping = @"opponent-typing"; // 对方正在输入中
XYSocketResponseType const XYSocketResponseTypeOpponentReadMessage = @"opponent-read-message"; // 对方消息已读回执

@interface XYWebSocketClient () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, copy) void (^ receiveMessageCallback)(id message);
@property (nonatomic, assign) NSInteger reconnectCount;
@property (nonatomic, copy) NSString *opponent;
@property (nonatomic, weak) NSTimer *heartBeatTimer;
@property (nonatomic, assign) NSInteger pongCount;
@property (nonatomic, assign) NSInteger pingCount;
// 避免在正在连接时，一定时间内websocket重复的重试连接
@property (nonatomic, assign) BOOL lockReconnect;

@end

@implementation XYWebSocketClient

- (void)dealloc {
    [self close];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxReconnectCount = 5;
        _overtime = 5;
        _reconnectCount = 0;
        _pingCount = 0;
        _pongCount = 0;
        _lockReconnect = NO;
        [self addObserver];
    }
    return self;
}


#pragma mark - Send packet methods

// 连接websocket服务器
- (void)openWithOpponent:(NSString *)username {
    dispatch_main_async_safe(^{
        // 开启成功后重置重连计数器
        self.reconnectCount = 0;
        self.opponent = username;
        [self open];
    });
    
}

- (void)open {
    dispatch_main_async_safe(^{
        [self.socket close];
        self.socket.delegate = nil;
        
        NSString *wssHostStr = [NSString stringWithFormat:@"%@/?%@=%@&opponent=%@", kWebSocketHost, kWebSocketTokenKey, [XYAuthenticationManager manager].authToken, self.opponent];
        NSURL *url = [NSURL URLWithString:wssHostStr];
        self.socket = [[SRWebSocket alloc] initWithURLRequest:[[NSURLRequest alloc] initWithURL:url]];
        self.socket.delegate = self;
        [self.socket open];
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        queue.maxConcurrentOperationCount = 1;
        [self.socket setDelegateOperationQueue:queue];
        
        [self addObserver];
    });
    
}

// 关闭连接
- (void)close {
    dispatch_main_async_safe(^{
        [self sendClosePacket];
        self.status = XYSocketStatusClosed;
        [self.socket close];
        self.socket = nil;
        [self destoryHeartBeat];
        [self removeObserver];
    });
    
}

- (void)sendMessage:(NSString *)message {
    dispatch_main_async_safe(^{
        switch (self.status) {
            case XYSocketStatusConnected: {
                if (self.socket.readyState == SR_OPEN) {
                    NSLog(@"发送中。。。");
                    NSString *packet = [self messageConstructorWithText:message username:self.opponent];
                    [self safeSendPacket:packet];
                }
                break;
            }
            case XYSocketStatusFailed:
                NSLog(@"当前连接状态失败，无法发送");
                break;
            case XYSocketStatusClosed:
                NSLog(@"当前连接已关闭");
                break;
        }
    });
}

// 安全发送数据包，防止未连接状态发送导致的crash
- (void)safeSendPacket:(NSString *)packet {
    if (packet.length == 0) {
        return;
    }
    dispatch_main_async_safe(^{
        switch (self.status) {
            case XYSocketStatusConnected: {
                NSLog(@"正在发送：%@", packet);
                [self.socket send:packet];
                break;
            }
            case XYSocketStatusFailed:
                NSLog(@"当前连接状态失败，无法发送");
                break;
            case XYSocketStatusClosed:
                NSLog(@"当前连接已关闭");
                break;
        }
    });
}

// 发送ping，用于维持不断线
- (void)sendPing {
    dispatch_main_async_safe(^{
        switch (self.status) {
            case XYSocketStatusConnected: {
                NSLog(@"发送ping");
                [self.socket sendPing:[NSData data]];
                break;
            }
            case XYSocketStatusFailed:
                NSLog(@"当前连接状态失败，无法发送");
                break;
            case XYSocketStatusClosed:
                NSLog(@"当前连接已关闭");
                break;
        }
    });
}

// 发送以 获取当前聊天室中已活跃的用户列表
- (void)sendNewUserPacket {
    NSDictionary *dict = @{
        @"type": XYSocketRequestTypeNewUser,
        kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
    };
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"获取当前聊天室中已活跃的用户列表");
    [self safeSendPacket:packet];
}

// 发送上线的数据包
- (void)sendConnectPacket {
    NSDictionary *dict = @{
                           @"type": XYSocketRequestTypeOnline,
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           };
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"正在发送上线的数据包");
    [self safeSendPacket:packet];
}

// 检测对方是否在线
// 最好在 websocket 连接成功后，发送此数据包
- (void)sendOnlineCheckPacket {
    NSDictionary *dict = @{
        @"type": XYSocketRequestTypeCheckOnline,
        kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
        @"username": self.opponent
    };
    
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"正在发送检查对方是否在线的数据包");
    [self safeSendPacket:packet];
}

// 发送离线的数据包
- (void)sendClosePacket {
    NSDictionary *dict = @{
                           @"type": XYSocketRequestTypeOffline,
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           @"username": self.opponent
                           };
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"正在发送我下线的数据包");
    
    [self safeSendPacket:packet];
}

// 发送已读消息数据包
- (void)sendReadMessagePacketWithMessageId:(NSString *)messageId {
    NSDictionary *dict = @{
        @"type": XYSocketRequestTypeReadMessage,
        kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
        @"username": self.opponent,
        @"message_id": messageId,
    };
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"正在发送已读消息的数据包");
    [self safeSendPacket:packet];
}

// 告诉对方我正在输入， 键盘在输入时，发送正在输入的数据包
- (void)sendTypingPacket {
    NSDictionary *dict = @{
                           @"type": XYSocketRequestTypeIsTyping,
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           @"username": self.opponent,
                           @"typing": @(YES),
                           };
    NSString *packet = [self jsonWithDict:dict];
    NSLog(@"正在发送正在输入的数据包");
    [self safeSendPacket:packet];
}


// 重置心跳
// 通过定时器，发送ping，服务器返回pong，维持websocket一直在线，防止一定的时间内未与服务器通讯，导致websocket超时断开请求
- (void)resetHearBeat {
    dispatch_main_async_safe(^{
        [self destoryHeartBeat];
        
        __weak typeof (self) weakSelf=self;
        //心跳设置为3分钟，NAT超时一般为5分钟
        weakSelf.heartBeatTimer= [XYSafeTimer scheduledTimerWithTimeInterval:15 repeats:YES block:^(NSTimer * _Nonnull timer) {
            // 这里发送一个ping，服务端返回pong，
            weakSelf.pingCount += 1;
            [weakSelf sendPing];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // 如果ping 和 pong 在一定时间后不相同则可能已经断开，应该断开重连，具体根据nginx设置的超时时间，说明服务端主动断开了
                // 如果onclose会执行reconnect，我们执行close()并且重连
                if (weakSelf.pingCount != weakSelf.pongCount) {
                    // 30秒后未收到pong，认为与服务器连接已断开
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf reconnect];
                    });
                }
                
            });
        }];
        [[NSRunLoop currentRunLoop] addTimer:weakSelf.heartBeatTimer forMode:NSRunLoopCommonModes];
    });
}

//  取消心跳
- (void)destoryHeartBeat {
    if (self.heartBeatTimer) {
        [self.heartBeatTimer invalidate];
        self.heartBeatTimer = nil;
    }
}


#pragma mark - Observer methods

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
}

- (void)willEnterForeground {
    [self open];
}

- (void)didEnterBackground {
    [self close];
}


#pragma mark - Private methods

- (void)onReceiveMessageCallback:(void (^)(NSDictionary * _Nonnull))callback {
    self.receiveMessageCallback = callback;
}

// 重新连接websocket服务器，对断线做处理
// 重新连接websocket没有使用定时器，而是在连接失败或者被服务器断开后，才会尝试重新尝试
- (void)reconnect {
    dispatch_main_async_safe(^{
        if (self.lockReconnect) {
            return;
        }
        self.lockReconnect = YES;
        
        // 3秒钟后再重试
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.lockReconnect = NO;
            BOOL isLogin = [[XYAuthenticationManager manager] isLogin];
            if (!isLogin) {
                [self close];
                return;
            }
            
            if (self.reconnectCount < self.maxReconnectCount - 1 &&
                self.status == XYSocketStatusFailed) {
                self.reconnectCount ++;
                [self open];
            }
        });
    });
    
}

// 消息最终包装为json发送给服务器
- (NSString *)messageConstructorWithText:(NSString *)text username:(NSString *)username {
    if (text.length == 0 || username.length == 0) {
        return nil;
    }
    
    // 根据服务端制定的规范，发送消息
    NSDictionary *data = @{
                           @"type": XYSocketRequestTypeNewMessage,
                           kWebSocketTokenKey: [XYAuthenticationManager manager].authToken,
                           @"username": username,
                           @"message": text
                           };
    
    return [self jsonWithDict:data];
}

- (NSString *)jsonWithDict:(NSDictionary *)dict {
    NSError  *parseError = nil;
    NSData   *jsonData   = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&parseError];
    if (parseError) {
        return nil;
    }
    NSString *jsonstr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonstr;
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    dispatch_main_async_safe(^{
        NSLog(@"已经与【%@】建立连接", self.opponent);
        self.status = XYSocketStatusConnected;
        [self sendConnectPacket];
        [self sendOnlineCheckPacket];
        [self resetHearBeat];
    });
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    dispatch_main_async_safe(^{
        NSLog(@"连接失败");
        self.status = XYSocketStatusFailed;
        [self reconnect];
    });
}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    dispatch_main_async_safe(^{
        NSData *packet = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:packet options:NSJSONReadingAllowFragments error:nil];
        
        NSString *type = messageDict[XYSocketResponseTypeKey];
        if (type == nil) {
            return;
        }
        
        if ([type isEqualToString:XYSocketResponseTypeGoneOnline]) {
            NSArray *usernames = messageDict[@"usernames"];
#if DEBUG
            for (NSInteger i = 0; i < usernames.count; i++) {
                NSLog(@"已上线: %@", usernames[i]);
            }
#endif
            if (self.receiveMessageCallback) {
                self.receiveMessageCallback(messageDict);
            }
        }
        else if ([type isEqualToString:XYSocketResponseTypeGoneOffline]) {
            NSLog(@"对方已下线: %@", self.opponent);
            if (self.receiveMessageCallback) {
                self.receiveMessageCallback(messageDict);
            }
        }
        else if ([type isEqualToString:@"new-message"]) {
            // 收到新消息
            if ([messageDict[@"sender_name"] isEqualToString:self.opponent]) {
                // 添加这个消息到消息列表
                if ([messageDict[@"sender_name"] isEqualToString:self.opponent]) {
                    [self sendReadMessagePacketWithMessageId:messageDict[@"message_id"]];
                }
                if (self.receiveMessageCallback) {
                    self.receiveMessageCallback(messageDict);
                }
                NSLog(@"接收到【%@】给【%@】发送的的消息:\n %@", messageDict[@"sender_name"], messageDict[@"username"], messageDict[@"message"]);
            }
        }
        else if ([type isEqualToString:XYSocketResponseTypeOpponentTyping]) {
            NSLog(@"对方正在输入: %@", self.opponent);
            if (self.receiveMessageCallback) {
                self.receiveMessageCallback(messageDict);
            }
        }
        else if ([type isEqualToString:XYSocketResponseTypeOpponentReadMessage]) {
            if ([messageDict[@"sender_name"] isEqualToString:self.opponent]) {
                NSLog(@"对方消息已读: %@", self.opponent);
            }
            if (self.receiveMessageCallback) {
                self.receiveMessageCallback(messageDict);
            }
        }
        else {
            NSLog(@"error: %@", messageDict);
        }
        
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    dispatch_main_async_safe(^{
        if (reason) {
            NSLog(@"连接关闭，code:%ld,reason:%@,wasClean:%d",(long)code,reason,wasClean);
            // https://www.jianshu.com/p/96080bc6b35c
            // 连接成功后，有收到心跳信息，然后断开，断开信息：code:1001 reason :Stream end encountered wasclean:0
            // 解析：1001，离开。在收到心跳包的情况下，出现断开，这种情况只有服务器发送心跳包给你，你没有回复服务器，服务器默认你离开了。
            // 解决方法：回复心跳包给服务器，心跳包一问一答的对话方式保持socket连接。
            self.status = XYSocketStatusFailed;
            [self reconnect];
        }
    });
   
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"接收到pong");
    self.pongCount += 1;
}

@end
