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
// next
// get 请求时返回下一页的链接
// post 请求时返回下一页的页码
// 没有时返回null
// http://chat.enba.com/api/message/?dialog=1&ordering=-created&page=2&page_size=20";
@property (nonatomic, strong) id next;
// previous = "<null>
@property (nonatomic, strong) id previous;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, readonly) Class contentClass;

- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(Class)rsClass reverse:(BOOL)reverse;
- (instancetype)initWithDict:(NSDictionary *)dict resultClass:(Class)rsClass;

@end

NS_ASSUME_NONNULL_END
