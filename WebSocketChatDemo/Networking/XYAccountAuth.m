//
//  XYAccountAuth.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYAccountAuth.h"
#import <AFNetworking.h>
#import "XYAuthenticationManager.h"

@implementation XYAccountAuth

+ (NSURLSessionDataTask *)loginWithMobile:(NSString *)mobile password:(NSString *)password completionHandler:(void (^)(NSURLSessionDataTask * _Nonnull, XYUser * _Nullable, NSError * _Nullable))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/login/", kBaseURLString];
    
    NSDictionary *parameters = @{@"mobile": mobile, @"password": password};
    // 忽略缓存
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    return [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                NSDictionary *userDict = responseObject[@"user"];
                NSString *token = responseObject[@"token"];
                XYUser *user = [[XYUser alloc] initWithDict:userDict];
                [[XYAuthenticationManager manager] setUser:user];
                [[XYAuthenticationManager manager] setAuthToken:token];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (user && token) {
                        completion(task, user, nil);
                    }
                    else {
                        completion(task, nil, [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:responseObject]);
                    }
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(task, nil, [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:responseObject]);
                });
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(task, nil, error);
        }
    }];
}

+ (NSURLSessionDataTask * _Nullable)heartbeatWithCompletionHandler:(void (^)(NSURLSessionDataTask * _Nullable, BOOL, NSError * _Nullable))completion {
    NSString *url = [NSString stringWithFormat:@"%@/heartbeat/", kBaseURLString];
    
    if ([XYAuthenticationManager manager].isLogin == NO) {
        if (completion) {
            completion(nil, NO, [NSError errorWithDomain:@"LoginInValid" code:-1 userInfo:nil]);
        }
        return nil;
    }
    
    NSDictionary *parameters = @{@"token": [XYAuthenticationManager manager].authToken};
    // 忽略缓存
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    return [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                NSDictionary *userDict = responseObject[@"user"];
                NSString *token = responseObject[@"token"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (userDict && token) {
                        completion(task, YES, nil);
                    }
                    else {
                        completion(task, NO, [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:responseObject]);
                    }
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(task, NO, [NSError errorWithDomain:NSURLErrorDomain code:response.statusCode userInfo:responseObject]);
                });
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSHTTPURLResponse *response = (id)task.response;
        // 服务没有打开时response 为 nil
        if (response && response.statusCode == 400) {
            // 400 为 参数错误 登陆失效，比如token错了或者token这个字段传错了
            if (completion) {
                completion(task, NO, error);
            }
        }
        else {
            // 其他响应code 不处理，可能是超时了，或者服务器本身的错误
        }
        
    }];
}

@end
