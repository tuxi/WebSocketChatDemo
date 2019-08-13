//
//  XYChatListViewController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYDialogListViewController.h"
#import "XYDialogListViewModel.h"
#import <MJRefresh.h>
#import "XYMessageListViewController.h"
#import "XYAuthenticationManager.h"
#import "XYLoginViewController.h"

@interface XYDialogListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XYDialogListViewModel *viewModel;

@end

@implementation XYDialogListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUI];
    [self setupHeaderRefresh];
    if ([XYAuthenticationManager manager].isLogin) {
        [self.tableView.mj_header beginRefreshing];
    }
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"聊天列表";
    
    [self.view addSubview:self.tableView];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStyleDone target:self action:@selector(logout)];
}

- (void)setupHeaderRefresh {
    if (self.tableView.mj_header != nil) {
        return;
    }
     __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshStateHeader headerWithRefreshingBlock:^{
        [weakSelf getDataFromServer:NO];
    }];
}

- (void)setupFooterRefresh {
    if (self.tableView.mj_footer != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_footer = [MJRefreshAutoFooter footerWithRefreshingBlock:^{
        [weakSelf getDataFromServer:YES];
    }];
                                
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
}

- (void)getDataFromServer:(BOOL)isMore {
    __weak typeof(self) weakSelf = self;
    [self.viewModel getMyDialogsWithIsMore:isMore completionHandler:^(NSArray<XYDialog *> * _Nullable dialogs, NSError * _Nullable error) {
        if (error) {
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
            return;
        }
        if (isMore == NO) {
            [self.tableView.mj_footer resetNoMoreData];
        }
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];
        
        if (weakSelf.viewModel.hasMore) {
            [weakSelf setupFooterRefresh];
        }
        else {
            [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
        }
        
        [weakSelf.tableView reloadData];
    }];
    
}

#pragma mark - Actions

- (void)logout {
    [[XYAuthenticationManager manager] invalidate];
    [[XYLoginViewController sharedInstance] showWithStyle:XYLoginViewStyleLogin animated:YES closeable:NO superController:self];
}

- (void)loginSuccess {
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellIdentifier = @"XYDialogTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdentifier];
    }
    XYDialog *model = self.viewModel.data[indexPath.row];
    cell.textLabel.text = model.opponent.username;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"last message: %@", model.modified];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    XYMessageListViewController *vc = [[XYMessageListViewController alloc] initWithDialog:self.viewModel.data[indexPath.row]];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Lazy

- (XYDialogListViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [XYDialogListViewModel new];
    }
    return _viewModel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}


@end
