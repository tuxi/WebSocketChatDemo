//
//  XYAuthenticationManager.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYAuthenticationManager.h"

static NSString * const kAuthTokenKey = @"auth_token";
static NSString * const kAuthUserKey = @"auth_user";

@implementation XYAuthenticationManager

@synthesize authToken = _authToken;
@synthesize user = _user;

+ (instancetype)manager {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = self.new;
    });
    return _instance;
}

- (void)setAuthToken:(NSString *)authToken {
    [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:kAuthTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _authToken = authToken;
}

- (NSString *)authToken {
    if (_authToken == nil) {
        return _authToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAuthTokenKey];
    }
    return _authToken;
}

- (void)setUser:(XYUser *)user {
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:user requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAuthUserKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _user = user;
}

- (XYUser *)user {
    if (_user == nil) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kAuthUserKey];
        return _user = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return _user;
}

- (BOOL)isLogin {
    return self.authToken.length && self.user;
}

@end
