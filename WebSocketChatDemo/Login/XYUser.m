//
//  XYUser.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYUser.h"

@implementation XYUser

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.username = [aDecoder decodeObjectForKey:@"username"];
        self.nickname = [aDecoder decodeObjectForKey:@"nickname"];
        self.avatar = [aDecoder decodeObjectForKey:@"avatar"];
        self.mobile = [aDecoder decodeObjectForKey:@"mobile"];
        self.address = [aDecoder decodeObjectForKey:@"address"];
        self.gender = [aDecoder decodeIntegerForKey:@"gender"];
        self.is_active = [aDecoder decodeBoolForKey:@"is_active"];
        self.summary = [aDecoder decodeObjectForKey:@"summary"];
        self.email = [aDecoder decodeObjectForKey:@"email"];
        self.head_background = [aDecoder decodeObjectForKey:@"head_background"];
        self.website = [aDecoder decodeObjectForKey:@"website"];
        self.birthday = [aDecoder decodeObjectForKey:@"birthday"];
        self.userId = [aDecoder decodeIntegerForKey:@"userId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.nickname forKey:@"nickname"];
    [aCoder encodeObject:self.avatar forKey:@"avatar"];
    [aCoder encodeObject:self.mobile forKey:@"mobile"];
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeInteger:self.gender forKey:@"gender"];
    [aCoder encodeBool:self.is_active forKey:@"is_active"];
    [aCoder encodeObject:self.summary forKey:@"summary"];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeObject:self.head_background forKey:@"head_background"];
    [aCoder encodeObject:self.website forKey:@"website"];
    [aCoder encodeObject:self.birthday forKey:@"birthday"];
    [aCoder encodeInteger:self.userId forKey:@"userId"];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"gender"]) {
        if ([value isEqualToString:@"male"]) {
            value = @(XYUserGenderMale);
        }
        else {
            value = @(XYUserGenderFemle);
        }
    }
    if ([key isEqualToString:@"id"]) {
        key = @"userId";
    }
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

@end
