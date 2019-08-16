//
//  XYMessageListViewModel.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYMessageListViewModel.h"
#import "XYApiClient.h"

@implementation XYMessageListViewModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        _page = 1;
        _hasMore = YES;
    }
    return self;
}

- (void)getMessagesByDialog:(XYDialog *)dialog isMore:(BOOL)isMore completionHandler:(void (^)(NSArray<XYMessage *> * _Nullable, NSError * _Nullable))completion {
    if (isMore == NO) {
        self.page = 1;
    }
    if (self.hasMore == NO) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"InvalidPage" code:404 userInfo:@{@"detail": @"Invalid page."}]);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [XYApiClient getMessagesByDialogId:dialog.dialogId page:self.page
                     completionHandler:^(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        }
        else {
            if (response.next == nil) {
                weakSelf.hasMore = NO;
            }
            else {
                self.page += 1;
            }
            if (!isMore) {
                [self.data removeAllObjects];
                [self.messageArray removeAllObjects];
            }
            [self.data addObjectsFromArray:response.results];
            [response.results enumerateObjectsUsingBlock:^(XYMessage *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                XYUser *sender = nil;
                if (dialog.owner.userId == model.sender) {
                    sender = dialog.owner;
                }
                else {
                    sender = dialog.opponent;
                }
                JSQMessage *message = [[JSQMessage alloc]initWithSenderId:sender.username senderDisplayName:sender.nickname?:sender.username date:model.createDate text:model.text];
                [self.messageArray addObject:message];
            }];
            completion(response.results, nil);
        }
    }];
}

- (NSMutableArray<XYMessage *> *)data {
    if (!_data) {
        _data = [NSMutableArray arrayWithCapacity:3];
    }
    return _data;
}

- (NSMutableArray<JSQMessage *> *)messageArray {
    if (!_messageArray) {
        _messageArray = @[].mutableCopy;
    }
    return _messageArray;
}

@end
