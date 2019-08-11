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

extern NSString * const kBaseURLString;

@implementation XYApiClient

+ (NSURLSessionDataTask *)getMyDialogsWithCompletionHandler:(void (^)(NSURLSessionDataTask * _Nullable, XYApiClientResponse * _Nullable, NSError * _Nullable))completion {
    
    if ([XYAuthenticationManager manager].isLogin == NO) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"XYAuthenticationError" code:500 userInfo:@{@"auth" : @"用户未登陆"}];
            completion(nil, nil, error);
        }
        return nil;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/dialog/", kBaseURLString];
    
    // 将jwt传递给服务端，用于身份验证
    NSString *token = [NSString stringWithFormat:@"JWT %@", [XYAuthenticationManager manager].authToken];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    return [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion) {
            NSHTTPURLResponse *response = (id)task.response;
            if (response.statusCode == 200) {
                XYApiClientResponse *rs = [[XYApiClientResponse alloc] initWithDict:responseObject resultClass:[XYDialog class]];
                
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
            completion(task, nil, error);
        }
    }];
}

@end


@implementation XYApiClientResponse {
    Class _contentClass;
}

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(nonnull Class)rsClass {
    if (self = [super init]) {
        _contentClass = rsClass;
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}


- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"results"]) {
        if (![value isKindOfClass:[NSArray class]]) {
            value = nil;
        }
        else {
            NSMutableArray *contents = [NSMutableArray arrayWithCapacity:[value count]];
            Class content_class = _contentClass;
            [(NSArray *)value enumerateObjectsUsingBlock:^(id  _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
                id content = [[content_class alloc] init];
                [content setValuesForKeysWithDictionary:dict];
                [contents addObject:content];
            }];
            value = contents;
        }
    }
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)setNilValueForKey:(NSString *)key {}

@end
