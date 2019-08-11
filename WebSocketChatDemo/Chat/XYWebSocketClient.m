//
//  XYWebSocketClient.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYWebSocketClient.h"
#import <SRWebSocket.h>

@interface XYWebSocketClient () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *socket;
// 重连定时器
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isUserStop;
@property (nonatomic, copy) void (^ receiveMessageCallback)(id message);

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

#pragma mark - Public methods


// 连接websocket服务器
- (void)startWithHost:(NSURL *)host {
    self.socket = [[SRWebSocket alloc] initWithURL:host];
    self.socket.delegate = self;
    [self.socket open];
}

// 结束连接
- (void)stop {
    self.isUserStop = YES;
    [self.timer invalidate];
    self.timer = nil;
    [self.socket close];
    self.socket = nil;
}

- (void)onReceiveMessageCallback:(void (^)(id _Nonnull))callback {
    self.receiveMessageCallback = callback;
}

- (void)sendMessageToOpponent:(NSString *)username message:(NSString *)message {
    NSString *jsonstr = [self messageConstructorWithText:message username:username];
    if (jsonstr == nil) {
        return;
    }
    [self.socket send:jsonstr];
}

#pragma mark - Private methods


// 重新连接websocket服务器，对断线做处理
- (void)restart {
    if (self.socket && self.socket.readyState != SR_OPEN) {
        [self.timer invalidate];
        self.timer = nil;
        [self.socket open];
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
                           @"session_key":@"4yrbho3819sb55q9fzhcr786wz1u2zc0",
                           @"username":@"user_1",
                           @"message":text
                           };
    
    NSError  *parseError = nil;
    NSData   *jsonData   = [NSJSONSerialization dataWithJSONObject:data options:0 error:&parseError];
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
    self.timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(restart) userInfo:nil repeats:YES];
    [self.timer fire];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败");
    if (self.isUserStop == NO) {
        // 服务器掉线，重连
        [self restart];
    }
    else {
        // 如果由用户断开，不进行重连
        return;
    }
}
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"接收消息:\n %@",message);
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    // 收到消息后，保存到数据库
    
    if (self.receiveMessageCallback) {
        self.receiveMessageCallback(messageDict);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"连接关闭");
}
@end
