//
//  XYDialog.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDialog.h"

@implementation XYDialog

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"owner"] || [key isEqualToString:@"opponent"]) {
        value = [[XYUser alloc] initWithDict:value];
    }
    else if ([key isEqualToString:@"id"]) {
        key = @"dialogId";
    }
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

@end
