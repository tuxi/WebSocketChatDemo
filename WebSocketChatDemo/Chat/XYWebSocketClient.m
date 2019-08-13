//
//  XYWebSocketClient.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYWebSocketClient.h"
#import <SRWebSocket.h>
#import "XYAuthenticationManager.h"
#import "XYSafeTimer.h"

@interface XYWebSocketClient () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *socket;
// 重连定时器
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, copy) void (^ receiveMessageCallback)(id message);
@property (nonatomic, assign) NSInteger reconnectCount;
@property (nonatomic, copy) NSString *opponent;

@end

@implementation XYWebSocketClient

+ (instancetype)sharedInstance {
    static id _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self new];
    });
    return _instance;
}

- (void)dealloc {
    [self close];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxReconnectCount = 5;
        _overtime = 10;
        _reconnectCount = 0;
    }
    return self;
}


#pragma mark - Public methods

// 连接websocket服务器
- (void)openWithOpponent:(NSString *)username {
    
    // 开启成功后重置重连计数器
    _reconnectCount = 0;
    self.opponent = username;
    [self open];
}

- (void)open {
    [self.socket close];
    self.socket.delegate = nil;
//    NSString *wssHostStr = [NSString stringWithFormat:@"%@/%@/%@", kBaseHost,  [XYAuthenticationManager manager].authToken, self.opponent];
    NSString *wssHostStr = [NSString stringWithFormat:@"%@/?%@=%@&opponent=%@", kWebSocketHost, kWebSocketTokenKey, [XYAuthenticationManager manager].authToken, self.opponent];
    NSURL *url = [NSURL URLWithString:wssHostStr];
    self.socket = [[SRWebSocket alloc] initWithURLRequest:[[NSURLRequest alloc] initWithURL:url]];
    self.socket.delegate = self;
    
    [self.socket open];
    //    self.socket sendPing:<#(NSData *)#>
    //    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    //    queue.maxConcurrentOperationCount = 1;
    //    [self.socket setDelegateOperationQueue:queue];
}

// 结束连接
- (void)close {
    
    [self sendClosePacket];
    [self.socket close];
    self.socket = nil;
    [self.timer invalidate];
    self.timer = nil;
    self.status = XYSocketStatusClosedByUser;
}

- (void)sendMessage:(NSString *)message {
    switch (self.status) {
        case XYSocketStatusConnected: {
            NSLog(@"发送中。。。");
            [self sendMessageToOpponent:self.opponent message:message];
            break;
        }
        case XYSocketStatusFailed:
            NSLog(@"发送失败");
            break;
        case XYSocketStatusClosedByServer:
            NSLog(@"已经关闭");
            break;
        case XYSocketStatusClosedByUser:
            NSLog(@"已经关闭");
            break;
    }
}

- (void)sendMessageToOpponent:(NSString *)username message:(NSString *)message {
    NSString *jsonstr = [self messageConstructorWithText:message username:username];
    if (jsonstr == nil) {
        return;
    }
    [self.socket send:jsonstr];
}

// 发送上线的数据包
- (void)sendConnectPacket {
    NSDictionary *dict = @{
                           @"type": @"online",
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           };
    NSString *jsonStr = [self jsonWithDict:dict];
    NSLog(@"connected, sending: %@", jsonStr);
    [self.socket send:jsonStr];
}

// websocket 连接成功后，检测对方是否在线
- (void)sendOnlineCheckPacket {
    NSDictionary *dict = @{
        @"type": @"check-online",
        kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
        @"username": self.opponent
    };
    
    NSString *jsonStr = [self jsonWithDict:dict];
    NSLog(@"checking online opponents with: %@", jsonStr);
    [self.socket send:jsonStr];
}

- (void)sendClosePacket {
    NSDictionary *dict = @{
                           @"type": @"offline",
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           @"username": self.opponent
                           };
    NSString *jsonStr = [self jsonWithDict:dict];
    NSLog(@"unloading, sending: %@", jsonStr);
    [self.socket send:jsonStr];
}

// 发送已读消息数据包
- (void)sendReadMessagePacketWithMessageId:(NSString *)messageId {
    NSDictionary *dict = @{
                           @"type": @"read_message",
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           @"username": self.opponent,
                           @"message_id": messageId,
                           };
    NSString *jsonStr = [self jsonWithDict:dict];
    NSLog(@"read message, sending: %@", jsonStr);
    [self.socket send:jsonStr];
}

// 告诉对方我正在输入， 键盘在输入时，发送正在输入的数据包
- (void)sendTypingPacket {
    NSDictionary *dict = @{
                           @"type": @"is-typing",
                           kWebSocketTokenKey : [XYAuthenticationManager manager].authToken,
                           @"username": self.opponent,
                           @"typing": @(YES),
                           };
    NSString *jsonStr = [self jsonWithDict:dict];
    NSLog(@"正在输入中: %@", jsonStr);
    [self.socket send:jsonStr];
}


#pragma mark - Private methods

- (void)onReceiveMessageCallback:(void (^)(id _Nonnull))callback {
    self.receiveMessageCallback = callback;
}

// 重新连接websocket服务器，对断线做处理
- (void)reconnect {
    
    BOOL isLogin = [[XYAuthenticationManager manager] isLogin];
    if (!isLogin) {
        [self.timer invalidate];
        self.timer = nil;
        [self.socket close];
        return;
    }
    // 计数+1
    if (_reconnectCount < self.maxReconnectCount - 1 && self.status != XYSocketStatusClosedByUser) {
        _reconnectCount ++;
        // 开启定时器
        NSTimer *timer = [XYSafeTimer scheduledTimerWithTimeInterval:self.overtime target:self selector:@selector(open) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.timer = timer;
    }
    else{
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}


// 消息最终包装为json发送给服务器
- (NSString *)messageConstructorWithText:(NSString *)text username:(NSString *)username {
    if (text.length == 0 || username.length == 0) {
        return nil;
    }
    
    // 根据服务端制定的规范，发送消息
    NSDictionary *data = @{
                           @"type":@"new-message",
                           kWebSocketTokenKey: [XYAuthenticationManager manager].authToken,
                           @"username": username,
                           @"message":text
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

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"已连接");
    self.status = XYSocketStatusConnected;
    [self sendConnectPacket];
    [self sendOnlineCheckPacket];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败");
    self.status = XYSocketStatusFailed;
    // 重连
    [self reconnect];
}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    
    NSData *packet = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:packet options:NSJSONReadingAllowFragments error:nil];
    
    // 收到消息后，保存到数据库
    
    NSString *type = messageDict[@"type"];
    if (type == nil) {
        return;
    }
    
    if ([type isEqualToString:@"gone-online"]) {
        // 对方已上线
        NSLog(@"对方已上线: %@", self.opponent);
    }
    else if ([type isEqualToString:@"gone-online"]) {
        // 对方已下线
         NSLog(@"对方已下线: %@", self.opponent);
    }
    else if ([type isEqualToString:@"new-message"]) {
        // 收到新消息
        if ([messageDict[@"sender_name"] isEqualToString:self.opponent] || [messageDict[@"send_name"] isEqualToString:[XYAuthenticationManager manager].user.username]) {
            // 添加这个消息到消息列表
            if ([messageDict[@"sender_name"] isEqualToString:self.opponent]) {
                [self sendReadMessagePacketWithMessageId:messageDict[@"id"]];
            }
        }
        NSLog(@"接收到【%@】的消息:\n %@", self.opponent, messageDict[@"message"]);
    }
    else if ([type isEqualToString:@"opponent-typing"]) {
        // 对方正在输入
        NSLog(@"对方正在输入: %@", self.opponent);
    }
    else if ([type isEqualToString:@"opponent-read-message"]) {
        // 对方消息已读
        if ([messageDict[@"sender_name"] isEqualToString:self.opponent]) {
            NSLog(@"对方消息已读: %@", self.opponent);
        }
    }
    else {
        NSLog(@"error: %@", messageDict);
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@" 发生错误，长连接断开");
    self.status = XYSocketStatusClosedByServer;
    [self reconnect];
}
- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"接收到服务器发送的pong消息");
}

@end
