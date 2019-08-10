//
//  XYUser.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XYUserGender) {
    XYUserGenderUnknow, // 未知
    XYUserGenderMale,  // 男
    XYUserGenderFemle, // 女
};

@interface XYUser : NSObject <NSCoding>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *avatar;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, assign) XYUserGender gender;
@property (nonatomic, assign) NSString *address;
@property (nonatomic, assign) BOOL is_active;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *head_background;
@property (nonatomic, copy) NSString *website;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) NSString *birthday;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
