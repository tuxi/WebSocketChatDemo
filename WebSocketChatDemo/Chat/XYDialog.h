//
//  XYDialog.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYDialog : NSObject

@property (nonatomic, assign) NSInteger dialogId;
@property (nonatomic, strong) XYUser *owner;
@property (nonatomic, strong) XYUser *opponent;
@property (nonatomic, copy) NSString *created;
@property (nonatomic, copy) NSString *modified;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
