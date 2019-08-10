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


static NSString * kBaseURLString = @"https://chat.enba.com";

@implementation XYAccountAuth

+ (NSURLSessionDataTask *)loginWithMobile:(NSString *)mobile password:(NSString *)password completionHandler:(void (^)(NSURLSessionDataTask * _Nonnull, XYUser * _Nullable, NSError * _Nullable))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/login/", kBaseURLString];
    
    NSDictionary *parameters = @{@"mobile": mobile, @"password": password};
    
    return [[AFHTTPSessionManager manager] POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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

@end
