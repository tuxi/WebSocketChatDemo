//
//  XYMessageListViewController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/11.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYMessageListViewController.h"
#import "XYApiClient.h"
#import "XYMessageListViewModel.h"
#import <JSQMessagesViewController/JSQMessages.h>
#import <MJRefresh/MJRefresh.h>
#import "XYWebSocketClient.h"
#import "XYAuthenticationManager.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define kBackGroundColor  UIColorFromRGB(0xf1f1f1)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue &0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00)>> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface XYMessageListViewController () <JSQMessagesComposerTextViewPasteDelegate>

@property (nonatomic, strong) XYMessageListViewModel *viewModel;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
// 对方
@property (nonatomic, strong) XYUser *opponent;
@property (nonatomic, strong) XYDialog *dialog;
@property (nonatomic, strong) XYWebSocketClient *wsClient;

@end

@implementation XYMessageListViewController

- (instancetype)initWithOpponent:(XYUser *)user dialog:(XYDialog *)dialog {
    if (self = [super init]) {
        _opponent = user;
        _dialog = dialog;
        
        self.wsClient = [[XYWebSocketClient alloc] init];
        __weak typeof(self) weakSelf = self;
        [self.wsClient onReceiveMessageCallback:^(NSDictionary * _Nonnull message) {
            JSQMessage *mObj = [JSQMessage messageWithSenderId:weakSelf.opponent.username displayName:weakSelf.opponent.nickname ?: weakSelf.opponent.username text:message[@"message"]];
            [weakSelf.viewModel.messageArray addObject:mObj];
            [weakSelf finishReceivingMessageAnimated:YES];
        }];
    }
    return self;
}

- (void)dealloc {
    [self.wsClient close];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    [self setupViews];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeNotification];
    [self.wsClient close];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addNotification];
    [self.wsClient openWithOpponent:self.opponent.username];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

- (void)initData {
    
    // 发送者id
    self.senderId = [XYAuthenticationManager manager].user.username;
    //发送者name
    self.senderDisplayName = self.opponent.nickname?: self.opponent.username;
}

- (void)setupViews {
    self.navigationItem.title = [NSString stringWithFormat:@"与%@聊天中...",self.senderDisplayName];
    self.collectionView.backgroundColor = kBackGroundColor;
    //绘制气泡
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    //更早消息
    self.showLoadEarlierMessagesHeader = YES;
    //输入框
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    //隐藏左侧多媒体输入按钮
    self.inputToolbar.contentView.leftBarButtonItemWidth = CGFLOAT_MIN;
    self.inputToolbar.contentView.leftContentPadding = CGFLOAT_MIN;
    //单元格自定义点击操作
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"自定义操作"
                                                                                      action:@selector(customAction:)] ];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];

    [self setupHeaderRefresh];
    [self.collectionView.mj_header beginRefreshing];
    
}

// 下拉刷新控件，下拉获取更多消息
- (void)setupHeaderRefresh {
    if (self.collectionView.mj_header != nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.collectionView.mj_header = [MJRefreshStateHeader headerWithRefreshingBlock:^{
        [weakSelf getMessagesFromServer];
    }];
}

- (void)getMessagesFromServer {
    __weak typeof(self) weakSelf = self;
    [self.viewModel getMessagesByDialog:self.dialog isMore:YES completionHandler:^(NSArray<XYMessage *> * _Nullable messages, NSError * _Nullable error) {
        [weakSelf.collectionView.mj_header endRefreshing];
        if (error) {
            return;
        }
        
        [weakSelf.collectionView reloadData];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [self.view resignFirstResponder];
    [self.inputToolbar.contentView.textView endEditing:YES];
}

#pragma mark - Notifications
- (void)didReceiveTextViewNotification:(NSNotification *)noftify {
    [self.wsClient sendTypingPacket];
}

#pragma mark - JSQMessagesViewController method overrides

//发送按钮点下
- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)senderDisplayName date:(NSDate *)date
{
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    [self.wsClient sendMessage:text];
    [self.viewModel.messageArray addObject:message];
    [self finishSendingMessageAnimated:YES];
}


#pragma mark - JSQMessages CollectionView DataSource
- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.viewModel.messageArray objectAtIndex:indexPath.item];
}

//删除某条消息
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.viewModel.messageArray removeObjectAtIndex:indexPath.item];
}
// 头像
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 暂时不显示头像
//    JSQMessage *message = [self.viewModel.messageArray objectAtIndex:indexPath.item];
//
//    JSQMessagesAvatarImage *cookImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:[message.senderId isEqualToString:self.senderId] ?@"demo_avatar_cook":@"demo_avatar_jobs"]
//                                                                                   diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
//    return cookImage;
    
    return nil;
}

// 消息气泡
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.viewModel.messageArray objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    return self.incomingBubbleImageData;
}
// 顶部显示时间label
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    //    if (indexPath.item % 3 == 0) {
    JSQMessage *message = [self.viewModel.messageArray objectAtIndex:indexPath.item];
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    //    }
    return nil;
}
//顶部显示发送者名称label
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.viewModel.messageArray objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.viewModel.messageArray objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}
//底部label
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}
#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.viewModel.messageArray count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    JSQMessage *msg = [self.viewModel.messageArray objectAtIndex:indexPath.item];
    if (!msg.isMediaMessage) {
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }else {
            cell.textView.textColor = [UIColor blackColor];
        }
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    NSURL *avatarURL = nil;
    if ([msg.senderId isEqualToString:self.opponent.username]) {
        avatarURL = [NSURL URLWithString:self.opponent.avatar];
    }
    else {
        avatarURL = [NSURL URLWithString:[XYAuthenticationManager manager].user.avatar];
    }
    [cell.avatarImageView sd_setImageWithURL:avatarURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
    }];
    
    return cell;
}

#pragma mark - Custom menu items
// 是否允许单元格自定义点击
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}
//单元格自定义点击事件
- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    [[[UIAlertView alloc] initWithTitle:@"单元格的自定义操作"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}

#pragma mark - Adjusting cell label heights
//设置时间label高度
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.viewModel.messageArray objectAtIndex:indexPath.item];
    
    // 默认显示第一个发送时间
    if (indexPath.item - 1>= 0) {
        JSQMessage *reMessage = [self.viewModel.messageArray objectAtIndex:indexPath.item-1];
        if([message.date isEqualToDate:reMessage.date]){
            return CGFLOAT_MIN;
        }
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}
//设置消息气泡上label的高度
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    //    JSQMessage *currentMessage = [self.messageArray objectAtIndex:indexPath.item];
    //    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
    //        return 0.0f;
    //    }
    //    if (indexPath.item - 1 > 0) {
    //        JSQMessage *previousMessage = [self.messageArray objectAtIndex:indexPath.item - 1];
    //        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
    //            return 0.0f;
    //        }
    //    }
    //    return kJSQMessagesCollectionViewCellLabelHeightDefault;
    return CGFLOAT_MIN;
}
//单元格底部label高度
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

//点击加载之前消息
- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"点击了加载之前的消息按钮");
}
//点击头像
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}
//点击消息气泡
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}
//点击单元格
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods
// 输入框粘贴
- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.viewModel.messageArray addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

- (XYMessageListViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [XYMessageListViewModel new];
    }
    return _viewModel;
}

@end
