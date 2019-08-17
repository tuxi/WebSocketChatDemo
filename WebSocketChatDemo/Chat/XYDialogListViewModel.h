//
//  XYDialogListViewModel.h
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYDialog.h"

NS_ASSUME_NONNULL_BEGIN

@interface XYDialogListViewModel : NSObject

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSMutableArray<XYDialog *> *dialogs;
@property (nonatomic, strong) NSMutableArray<XYUser *> *users;

- (void)getMyDialogsWithIsMore:(BOOL)isMore completionHandler:(void (^ _Nullable )(NSArray<XYDialog *> *_Nullable dialogs, NSError *_Nullable error))completion;
- (void)getMyFriendsWithIsMore:(BOOL)isMore completionHandler:(void (^ _Nullable )(NSArray<XYUser *> *_Nullable users, NSError *_Nullable error))completion;;
@end

NS_ASSUME_NONNULL_END
