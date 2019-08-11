//
//  XYMessage.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYMessage : NSObject

@property (nonatomic, assign) NSInteger messageId;
@property (nonatomic, assign) BOOL read;
@property (nonatomic, assign) BOOL is_removed;
@property (nonatomic, copy) NSString *created;
@property (nonatomic, copy) NSString *text;
// 发送消息的用户id
@property (nonatomic, assign) NSInteger sender;
@property (nonatomic, strong) NSDate *createDate;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
