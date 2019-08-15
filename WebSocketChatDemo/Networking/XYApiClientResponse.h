//
//  XYApiClientResponse.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYApiClientResponse : NSObject

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) NSInteger next;
@property (nonatomic, assign) NSInteger previous;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, readonly) Class contentClass;

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(Class)rsClass;

@end

NS_ASSUME_NONNULL_END
