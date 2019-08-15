//
//  XYMessageListViewController.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "XYDialog.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYMessageListViewController : JSQMessagesViewController

- (instancetype)initWithOpponent:(XYUser *)user dialog:(XYDialog *)dialog;

@end

NS_ASSUME_NONNULL_END
