//
//  XYAuthenticationManager.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYAuthenticationManager.h"
#import "XYAccountAuth.h"
#import "XYSafeTimer.h"
#import "XYLoginViewController.h"
#import "SVProgressHUD.h"

static NSString * const kAuthTokenKey = @"auth_token";
static NSString * const kAuthUserKey = @"auth_user";

@interface XYAuthenticationManager ()

@property (nonatomic, weak) NSTimer *timer;

@end

@implementation XYAuthenticationManager

@synthesize authToken = _authToken;
@synthesize user = _user;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)manager {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = self.new;
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoginSuccess:) name:kLoginSuccessNotification object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startHeartBeatLoop];
        });
    }
    return self;
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
    NSData *data = nil;
    if (user) {
        data = [NSKeyedArchiver archivedDataWithRootObject:user requiringSecureCoding:NO error:nil];
    }
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

- (void)invalidate {
    self.authToken = nil;
    self.user = nil;
    [self stopHeartBeatLoop];
}

#pragma mark - Private methods

- (void)startHeartBeatLoop {
    [self stopHeartBeatLoop];
    if (self.isLogin == NO) {
        return;
    }
    self.timer = [XYSafeTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(heartBeatAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopHeartBeatLoop {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)onLoginSuccess:(NSNotification *)notify {
    [self startHeartBeatLoop];
}

- (void)heartBeatAction {
    __weak typeof(self) weakSelf = self;
    [XYAccountAuth heartbeatWithCompletionHandler:^(NSURLSessionDataTask * _Nullable task, BOOL isValid, NSError * _Nullable error) {
        if (!isValid) {
            [weakSelf invalidate];
            [SVProgressHUD showErrorWithStatus:@"登陆已失效，请重新登录..."];
            dispatch_async(dispatch_get_main_queue(), ^{
                // 登陆失效，则弹出登陆页面
                UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
                [[XYLoginViewController sharedInstance] showWithStyle:XYLoginViewStyleLogin animated:YES closeable:NO superController:vc];
            });
            
        }
    }];
}


@end
