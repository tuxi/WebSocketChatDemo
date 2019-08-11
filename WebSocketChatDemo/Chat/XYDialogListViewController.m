//
//  XYChatListViewController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDialogListViewController.h"
#import "XYApiClient.h"

@interface XYDialogListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation XYDialogListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"聊天列表";
    
    [XYApiClient getMyDialogsWithCompletionHandler:^(NSURLSessionDataTask * _Nullable task, XYApiClientResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
}


@end
