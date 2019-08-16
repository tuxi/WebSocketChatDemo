//
//  XYApiClientResponse.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYApiClientResponse.h"

@implementation XYApiClientResponse {
    Class _contentClass;
    BOOL _reverse;
}

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(Class)rsClass {
    return [self initWithDict:dict resultClass:rsClass reverse:NO];
}

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(nonnull Class)rsClass reverse:(BOOL)reverse {
    if (self = [super init]) {
        _contentClass = rsClass;
        _reverse = reverse;
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (Class)contentClass {
    return _contentClass;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([value isKindOfClass:[NSNull class]]) {
        value = nil;
    }
    if ([key isEqualToString:@"results"]) {
        if (![value isKindOfClass:[NSArray class]]) {
            value = nil;
        }
        else {
            NSMutableArray *contents = [NSMutableArray arrayWithCapacity:[value count]];
            Class content_class = _contentClass;
            if (!_reverse) {
                [(NSArray *)value enumerateObjectsUsingBlock:^(id  _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
                    id content = [[content_class alloc] init];
                    [content setValuesForKeysWithDictionary:dict];
                    [contents addObject:content];
                }];
            }
            else {
                [(NSArray *)value enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
                    id content = [[content_class alloc] init];
                    [content setValuesForKeysWithDictionary:dict];
                    [contents addObject:content];
                }];
            }
            value = contents;
        }
    }
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)setNilValueForKey:(NSString *)key {}

@end
