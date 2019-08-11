//
//  XYDialogListViewModel.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDialogListViewModel.h"
#import "XYApiClient.h"

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

- (void)getMyDialogsWithIsMore:(BOOL)isMore completionHandler:(void (^)(NSArray<XYDialog *> * _Nullable, NSError * _Nullable))completion {
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
                [self.data removeAllObjects];
            }
            [self.data addObjectsFromArray:response.results];
            completion(response.results, nil);
        }
    }];
}

- (NSMutableArray<XYDialog *> *)data {
    if (!_data) {
        _data = [NSMutableArray arrayWithCapacity:3];
    }
    return _data;
}

@end
