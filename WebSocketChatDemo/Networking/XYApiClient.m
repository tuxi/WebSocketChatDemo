//
//  XYApiClient.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYApiClient.h"
#import "XYAuthenticationManager.h"
#import <AFNetworking.h>
#import "XYDialog.h"
#import "XYMessage.h"
#import "XYUser.h"

static NSInteger const kPageSize = 20;

@implementation XYApiClient

+ (NSURLSessionDataTask *)getMyDialogsWithPage:(NSInteger)page completionHandler:(void (^)(NSURLSessionDataTask * _Nullable, XYApiClientResponse * _Nullable, NSError * _Nullable))completion {
    
    if ([XYAuthenticationManager manager].isLogin == NO) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XYAuthenticationError" code:500 userInfo:@{@"auth" : @"用户未登陆"}];
            completion(nil, nil, error);
        }
        return nil;
    }
    
    page = MAX(1, page);
    NSString *url = [NSString stringWithFormat:@"%@/dialog/", kBaseURLString];
    
    // 忽略缓存
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    // 将jwt传递给服务端，用于身份验证
    NSString *token = [NSString stringWithFormat:@"JWT %@", [XYAuthenticationManager manager].authToken];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    return [manager GET:url parameters:@{@"page": @(page), @"page_size": @(kPageSize), @"ordering": @"-modified"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                XYApiClientResponse *rs = [[XYApiClientResponse alloc] initWithDict:responseObject resultClass:[XYDialog class] reverse:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(task, rs, nil);
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSHTTPURLResponse *response = (id)task.response;
                if (response.statusCode == 404) {
                    // 处理page 超出范围的Invalid page 问题
                    XYApiClientResponse *rs = [XYApiClientResponse new];
                    completion(task, rs, nil);
                }
                else {
                    completion(task, nil, error);
                }
            });
        }
    }];
}

+ (NSURLSessionDataTask *)getMessagesByDialogId:(NSInteger)dialogId page:(NSInteger)page completionHandler:(void (^)(NSURLSessionDataTask * _Nullable, XYApiClientResponse * _Nullable, NSError * _Nullable))completion {
    if ([XYAuthenticationManager manager].isLogin == NO) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XYAuthenticationError" code:500 userInfo:@{@"auth" : @"用户未登陆"}];
            completion(nil, nil, error);
        }
        return nil;
    }
    
    page = MAX(1, page);
    NSString *url = [NSString stringWithFormat:@"%@/message/", kBaseURLString];
    
    // 将jwt传递给服务端，用于身份验证
    NSString *token = [NSString stringWithFormat:@"JWT %@", [XYAuthenticationManager manager].authToken];
    // 忽略缓存 返回一个预设配置，没有持久性存储的缓存，Cookie或证书。这对于实现像"秘密浏览"功能的功能来说，是很理想的。
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:config];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    // -created 按创建时间降序排序
    // created 按创建时间升序排序
    NSDictionary *paramters = @{@"page": @(page),@"page_size": @(kPageSize),  @"dialog": @(dialogId), @"ordering": @"-created"};
    return [manager GET:url parameters:paramters progress:nil  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                XYApiClientResponse *rs = [[XYApiClientResponse alloc] initWithDict:responseObject resultClass:[XYMessage class] reverse:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(task, rs, nil);
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSHTTPURLResponse *response = (id)task.response;
                if (response.statusCode == 404) {
                    // 处理page 超出范围的Invalid page 问题
                    XYApiClientResponse *rs = [XYApiClientResponse new];
                    completion(task, rs, nil);
                }
                else {
                    completion(task, nil, error);
                }
            });
        }
    }];
}

+ (NSURLSessionDataTask *)getUsersWithPage:(NSInteger)page completionHandler:(void (^)(NSURLSessionDataTask * _Nullable, XYApiClientResponse * _Nullable, NSError * _Nullable))completion {
    if ([XYAuthenticationManager manager].isLogin == NO) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XYAuthenticationError" code:500 userInfo:@{@"auth" : @"用户未登陆"}];
            completion(nil, nil, error);
        }
        return nil;
    }
    
    page = MAX(1, page);
    NSString *url = [NSString stringWithFormat:@"%@/users/", kBaseURLString];
    
    // 将jwt传递给服务端，用于身份验证
    NSString *token = [NSString stringWithFormat:@"JWT %@", [XYAuthenticationManager manager].authToken];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    return [manager GET:url parameters:@{@"page": @(page),@"page_size": @(kPageSize)} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                XYApiClientResponse *rs = [[XYApiClientResponse alloc] initWithDict:responseObject resultClass:[XYUser class]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(task, rs, nil);
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
            dispatch_async(dispatch_get_main_queue(), ^{
                NSHTTPURLResponse *response = (id)task.response;
                if (response.statusCode == 404) {
                    // 处理page 超出范围的Invalid page 问题
                    XYApiClientResponse *rs = [XYApiClientResponse new];
                    completion(task, rs, nil);
                }
                else {
                    completion(task, nil, error);
                }
            });
        }
    }];
}

@end
