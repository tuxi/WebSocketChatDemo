//
//  XYMessageListViewModel.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYMessage.h"
#import <JSQMessagesViewController/JSQMessage.h>
#import "XYDialog.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYMessageListViewModel : NSObject

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSMutableArray<XYMessage *> *data;
@property (nonatomic, strong) NSMutableArray<JSQMessage *> *messageArray;

- (void)getMessagesByDialog:(XYDialog *)dialog isMore:(BOOL)isMore completionHandler:(void (^ _Nullable )(NSArray<XYMessage *> *_Nullable messages, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
