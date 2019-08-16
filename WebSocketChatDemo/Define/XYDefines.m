//
//  XYDefines.m
//  WebSocketChatDemo
//
//  Created by xiaoyuan on 2019/8/13.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDefines.h"


NSString * const kBaseURLString = @"https://chat.enba.com/api";
//NSString * const kBaseURLString = @"http://10.211.55.4/api";
//NSString * const kBaseURLString = @"http://127.0.0.1:8000/api";

// NSString *const kWebSocketHost = @"ws://10.211.55.4/ws";
//NSString *const kWebSocketHost = @"ws://127.0.0.1:5002";
NSString *const kWebSocketHost = @"wss://chat.enba.com/ws";

NSString * const kWebSocketTokenKey = @"token";

NSNotificationName const kLoginSuccessNotification = @"kLoginSuccess";
NSNotificationName const kLogloutNotification = @"kDidLogout";
