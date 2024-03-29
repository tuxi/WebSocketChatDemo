//
//  XYDialogListViewModel.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDialogListViewModel.h"
#import "XYApiClient.h"

@interface XYDialogListViewModel ()

@end

@implementation XYDialogListViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _page = 1;
        _hasMore = YES;
    }
    return self;
}

- (void)getMyFriendsWithIsMore:(BOOL)isMore completionHandler:(void (^ _Nullable)(NSArray<XYUser *> * _Nullable, NSError * _Nullable))completion {
    if (isMore == NO) {
        self.page = 1;
        self.hasMore = YES;
    }
    if (self.hasMore == NO) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"InvalidPage" code:404 userInfo:@{@"detail": @"Invalid page."}]);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [XYApiClient getUsersWithPage:self.page completionHandler:^(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        }
        else {
            if (response.next == 0) {
                weakSelf.hasMore = NO;
            }
            else {
                self.page += 1;
            }
            if (!isMore) {
                [self.users removeAllObjects];
            }
            [response.results enumerateObjectsUsingBlock:^(XYUser *  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.dialogs enumerateObjectsUsingBlock:^(XYDialog * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (![obj.owner.username isEqualToString:user.username] && ![obj.opponent.username isEqualToString:user.username]) {
                        [self.users addObject:user];
                    }
                }];
            }];
            completion(response.results, nil);
        }
    }];
}

- (void)getMyDialogsWithIsMore:(BOOL)isMore completionHandler:(void (^)(NSArray<XYDialog *> * _Nullable, NSError * _Nullable))completion {
    if (isMore == NO) {
        self.page = 1;
        self.hasMore = YES;
    }
    if (self.hasMore == NO) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"InvalidPage" code:404 userInfo:@{@"detail": @"Invalid page."}]);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [XYApiClient getMyDialogsWithPage:self.page completionHandler:^(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        }
        else {
            if (response.next == 0) {
                weakSelf.hasMore = NO;
            }
            else {
                self.page += 1;
            }
            if (!isMore) {
                [self.dialogs removeAllObjects];
            }
            [self.dialogs addObjectsFromArray:response.results];
            completion(response.results, nil);
        }
    }];
}

- (NSMutableArray<XYDialog *> *)dialogs {
    if (!_dialogs) {
        _dialogs = [NSMutableArray arrayWithCapacity:3];
    }
    return _dialogs;
}

@end
