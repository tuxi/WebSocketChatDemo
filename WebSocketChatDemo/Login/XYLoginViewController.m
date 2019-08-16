//
//  XYLoginViewController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYLoginViewController.h"
#import "FBShimmeringView.h"
#import "DeformationButton.h"
#import "XYSafeTimer.h"
#import "SVProgressHUD.h"
#import "XYAccountAuth.h"

#define kLoginViewHeightOffset 0
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kAccount @"account"

@interface XYLoginViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *phoneNum;
@property (weak, nonatomic) IBOutlet UITextField *pwdAndAuth;
@property (weak, nonatomic) IBOutlet UITextField *registPwd;
@property (weak, nonatomic) IBOutlet UIButton *login;
@property (weak, nonatomic) IBOutlet UIButton *forgetAndAuth;
@property (weak, nonatomic) IBOutlet UIButton *phoneRegist;
@property (weak, nonatomic) IBOutlet UIScrollView *backScrollView;
@property (weak, nonatomic) IBOutlet UIButton *changePwdBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeButon;
@property (weak, nonatomic) IBOutlet UIButton *weiboButton;
@property (weak, nonatomic) IBOutlet UIButton *QQButton;
@property (weak, nonatomic) IBOutlet UIButton *WechatButton;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property (weak, nonatomic) UIButton *maskBtn;
@property (nonatomic,weak) NSTimer *timer;//定时器
@property (nonatomic,assign) XYLoginViewStyle currentStyle;
@property (nonatomic,assign) XYLoginViewStyle lastStyle;
@property (nonatomic,strong) DeformationButton *deformation;
@property (nonatomic,strong) UIViewController *superVC;
@property (nonatomic, assign) BOOL isAppear;
@end

static XYLoginViewController *_instance = nil;

@implementation XYLoginViewController

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[XYLoginViewController alloc]init];
    });
    return _instance;
}

- (void)showWithStyle:(XYLoginViewStyle)style animated:(BOOL)animated closeable:(BOOL)closeable superController:(nonnull UIViewController *)superVC {
    self.currentStyle = style;
    UIView *aView = [UIApplication sharedApplication].delegate.window;
    self.superVC = superVC;
    self.view.frame = CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight - kLoginViewHeightOffset);
    // 添加遮罩按钮
    UIButton *maskBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kLoginViewHeightOffset)];
    maskBtn.backgroundColor = [UIColor clearColor];
    [maskBtn addTarget:self action:@selector(backToSuperVC:) forControlEvents:UIControlEventTouchUpInside];
    [aView addSubview: maskBtn];
    self.maskBtn = maskBtn;
    [aView addSubview: self.view];
    [self.superVC addChildViewController:self];
    [self didMoveToParentViewController:self.superVC];
    
    if (animated) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.view.frame = CGRectMake(0, kLoginViewHeightOffset, kScreenWidth, kScreenHeight - kLoginViewHeightOffset + 20);
            self.superVC.view.transform = CGAffineTransformMakeScale(0.95, 0.95);
        } completion:nil];
    }
    else {
        self.view.frame = CGRectMake(0, kLoginViewHeightOffset, kScreenWidth, kScreenHeight - kLoginViewHeightOffset + 20);
        self.superVC.view.transform = CGAffineTransformMakeScale(0.95, 0.95);
    }
    self.closeButon.hidden = !closeable;
}

// 在XIB布局后才能改变视图结构，不然会被XIB改回去
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.currentStyle == XYLoginViewStyleLogin) {//记住账号名
        self.phoneNum.text = [[NSUserDefaults standardUserDefaults] objectForKey:kAccount];
    }
    [self changeModelHidden];
    [self recover];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastStyle = XYLoginViewStyleLogin;
    self.view.layer.cornerRadius = 10;
    self.backScrollView.contentSize = CGSizeMake(3500, kScreenHeight);
    self.backScrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backColor"]];
    self.backScrollView.scrollEnabled = NO;
    
    self.phoneNum.delegate = self;
    self.pwdAndAuth.delegate = self;
    self.registPwd.delegate = self;
    
    self.login.layer.borderColor = [UIColor whiteColor].CGColor;
    self.login.layer.borderWidth = 1;
    self.login.layer.cornerRadius = 10;
    
    self.changePwdBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    self.changePwdBtn.layer.borderWidth = 1;
    self.changePwdBtn.layer.cornerRadius = 10;
    self.changePwdBtn.alpha = 0;
    
    [self hidenThirdPartyLoginButtons:YES];
    
    // 添加shimmer效果,图片100 X 100
    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(kScreenWidth/2 - 50, 75, 100, 100)];
    [self.view addSubview:shimmeringView];
    shimmeringView.shimmeringPauseDuration = 1.5;
    shimmeringView.shimmeringSpeed = 150;
    UIImageView *logoView = [[UIImageView alloc]initWithFrame:shimmeringView.bounds];
    logoView.image = [UIImage imageNamed:@"icon_alpface_logo"];
    shimmeringView.contentView = logoView;
    // Start shimmering.
    shimmeringView.shimmering = YES;
    
}


// 重置背景位置和定时器
- (void)recover{
    self.isAppear = YES;
    //启动需要时间，应设置比动画时间长，否则有可能会图像越界
    self.timer = [XYSafeTimer scheduledTimerWithTimeInterval:16 target:self selector:@selector(scrollScrollViewIsRecover:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    [self scrollScrollViewIsRecover:YES];
}

- (void)hidenThirdPartyLoginButtons:(BOOL)hiden {
    self.weiboButton.hidden = hiden;
    self.QQButton.hidden = hiden;
    self.WechatButton.hidden = hiden;
    self.bottomLabel.hidden = hiden;
}


#pragma mark -- 背景平移动画
- (void)scrollScrollViewIsRecover:(BOOL)isRecover
{
    if (self.isAppear == NO) {
        return;
    }
    static BOOL direction = YES;
    if (isRecover) {
        direction = YES;
        self.backScrollView.contentOffset = CGPointMake(0, 0);
    }
    //YES代表向右
    CGPoint newScrollViewContentOffset = self.backScrollView.contentOffset;
    
    //一次移动多少个单位
    CGFloat dist = 3000;
    
    if (direction) {
        newScrollViewContentOffset.x += dist;
    }else {
        newScrollViewContentOffset.x -= dist;
    }
    
    //最后设置scollView's contentOffset
    [UIView animateWithDuration:15 animations:^{
        self.backScrollView.contentOffset = newScrollViewContentOffset;
    }completion:^(BOOL finished) {
        direction = !direction;
    }];
}

- (IBAction)backToSuperVC:(id)sender {
    [self.phoneNum resignFirstResponder];
    [self.pwdAndAuth resignFirstResponder];
    [self.registPwd resignFirstResponder];
    //销毁定时器
    [self.timer invalidate];
    self.timer = nil;
    self.isAppear = NO;
    
    self.phoneNum.text = @"";
    self.pwdAndAuth.text = @"";
    self.registPwd.text = @"";
    self.deformation.alpha = 0;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.superVC.view.transform = CGAffineTransformIdentity;
        self.view.frame = CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight - kLoginViewHeightOffset + 20);
    } completion:^(BOOL finished) {
        self.lastStyle = self.currentStyle;
        [self.maskBtn removeFromSuperview];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        [self didMoveToParentViewController:nil];
    }];
}

#pragma mark -- 各种按钮处理
//忘记密码和获取验证码
- (IBAction)forgetAndAuth:(id)sender {
    if (self.currentStyle == XYLoginViewStyleRegister || self.currentStyle == XYLoginViewStyleForget) {
        //注册模式
        if ([self phoneNumCheck]) {
            [self countDown];//开始倒计时
            [self sendSMS];//发送验证码
        }else{
            [self showLogin:self.login];
            [SVProgressHUD showErrorWithStatus:@"手机号不正确"];
        }
    }else if(self.currentStyle == XYLoginViewStyleLogin){
        //忘记密码模式
        self.currentStyle = XYLoginViewStyleForget;
        [self hiddenSubviews:YES duration:0.5];
        [self reverseView:UIViewAnimationTransitionFlipFromLeft];
    }
}

//正则表达式手机号检测
- (BOOL)phoneNumCheck{
    NSString *regex = @"^((13[0-9])|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pred evaluateWithObject:self.phoneNum.text];
}

//按钮倒计时效果
- (void)countDown{
    __block int time = 60;
    self.forgetAndAuth.enabled = NO;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer1 = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer1,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer1, ^{
        if(time<=0){
            dispatch_source_cancel(_timer1);
            dispatch_async(dispatch_get_main_queue(), ^{
                //倒计时结束操作
                self.forgetAndAuth.alpha = 1;
                self.forgetAndAuth.titleLabel.textColor = [UIColor whiteColor];
                [self.forgetAndAuth setTitle:@"获取验证码" forState:UIControlStateNormal];
                self.forgetAndAuth.enabled = YES;
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                //倒计时中操作
                self.forgetAndAuth.alpha = 0.5;
                NSString *strTime = [NSString stringWithFormat:@"%d秒后重发",time];
                [self.forgetAndAuth setTitle:strTime forState:UIControlStateNormal];
            });
            time--;
        }
    });
    dispatch_resume(_timer1);
}

/*
 发送验证码
 */
- (void)sendSMS{
#warning needTODO:发送验证码代码填写处
    [SVProgressHUD showSuccessWithStatus:@"发送成功"];
}

//验证验证码
-(void)verifySMS{
#warning needTODO:第三方短信验证代码，以及验证通过后与自己服务器网络对接
#warning needTODO:如果第三方验证失败或者错误，需要调用[self showLogin:self.login];否则按钮不会停止动画
}

//登录
- (IBAction)login:(id)sender {
    //其他按钮的交互取消
    [self userInteractionIsAllow:NO];
    [self startLoading:sender];
    //延时执行点击后操作，为确保动画完成一点样子，不需要的话，可以直接执行方法
    [self performSelector:@selector(loginButtonActions) withObject:nil afterDelay:1.2];
    
}

- (void)loginButtonActions {
    if (self.currentStyle == XYLoginViewStyleRegister) {
        // 注册模式
        if ([self phoneNumCheck]) { //有效手机号
            if (self.registPwd.text.length > 5 && self.registPwd.text.length < 16) {
                //验证验证码
                [self verifySMS];
            }else{
                [SVProgressHUD showInfoWithStatus:@"密码长度不符要求，请设置为5~15个字符内"];
                [self showLogin:self.login];
                return;
            }
        }
        else {
            [SVProgressHUD showInfoWithStatus:@"手机号不正确"];
            [self showLogin:self.login];
            return;
        }
    }
    else if (self.currentStyle == XYLoginViewStyleLogin){
        //登录模式
        if (self.phoneNum.text.length == 0) {
            [SVProgressHUD showErrorWithStatus:@"请输入账号"];
            [self showLogin:self.login];
            return;
        }
        if (self.pwdAndAuth.text.length == 0) {
            [SVProgressHUD showErrorWithStatus:@"请输入密码"];
            [self showLogin:self.login];
            return;
        }
        
        [self onLogin];
     
    }
    else {
        //忘记密码模式
        if([self phoneNumCheck]) { //有效手机号
            [self verifySMS];
        }else {
            [SVProgressHUD showInfoWithStatus:@"手机号不正确"];
        }
        [self showLogin:self.login];
    }
}

//开始按钮动画效果
- (void)startLoading:(UIButton *)sender{
    sender.alpha = 0;
    self.deformation = [[DeformationButton alloc]initWithFrame:sender.frame];
    [self.deformation.forDisplayButton setTitle:sender.titleLabel.text forState:UIControlStateNormal];
    self.deformation.forDisplayButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:self.deformation];
    [self.deformation loadingAction];
}

//停止按钮动画，展示原本按钮
-(void)showLogin:(UIButton *)sender{
    [self.deformation stopLoading];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.alpha = 1;
        [self.deformation removeFromSuperview];
        self.deformation = nil;
        [self userInteractionIsAllow:YES];
    });
}

//手机注册和返回到密码登录
- (IBAction)phoneRegistBtn:(id)sender {
    self.pwdAndAuth.text = @"";
    self.registPwd.text = @"";
    //进入注册模式
    if (self.currentStyle == XYLoginViewStyleForget) {
        //忘记密码模式,返回到登录模式
        [self hiddenSubviews:NO duration:0.5];
        [self reverseView:UIViewAnimationTransitionFlipFromRight];
        self.currentStyle = XYLoginViewStyleLogin;
    }else if(self.currentStyle == XYLoginViewStyleRegister){
        //进入登录模式
        self.pwdAndAuth.secureTextEntry = YES;
        [self.forgetAndAuth setTitle:@"忘记密码?" forState:UIControlStateNormal];
        self.pwdAndAuth.placeholder = @"请输入密码";
        [self.login setTitle:@"登录" forState:UIControlStateNormal];
        [self.phoneRegist setTitle:@"手机注册" forState:UIControlStateNormal];
        self.pwdAndAuth.keyboardType = UIKeyboardTypeDefault;
        //要变化的frame
        CGRect frame = self.login.frame;
        frame.origin.y -= 40;
        [UIView animateWithDuration:0.7 animations:^{
            self.registPwd.alpha = 0;
            self.login.frame = frame;
        }];
        self.currentStyle = XYLoginViewStyleLogin;
    }else{
        //相应名字修改
        self.pwdAndAuth.secureTextEntry = NO;
        [self.forgetAndAuth setTitle:@"获取验证码" forState:UIControlStateNormal];
        self.pwdAndAuth.placeholder = @"请输入验证码";
        [self.login setTitle:@"注册" forState:UIControlStateNormal];
        [self.phoneRegist setTitle:@"返回登录" forState:UIControlStateNormal];
        self.pwdAndAuth.keyboardType = UIKeyboardTypeNumberPad;
        //要变化的frame
        CGRect frame = self.login.frame;
        frame.origin.y += 40;
        [UIView animateWithDuration:0.7 animations:^{
            self.registPwd.alpha = 0.5;
            self.login.frame = frame;
        }];
        self.currentStyle = XYLoginViewStyleRegister;
    }
}

//翻转动画
-(void)reverseView:(UIViewAnimationTransition)direction{
    //翻转动画
    [UIView beginAnimations:@"doflip" context:nil];
    //设置时常
    [UIView setAnimationDuration:1];
    //设置动画淡入淡出
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    //设置代理
    [UIView setAnimationDelegate:self];
    //设置翻转方向
    [UIView setAnimationTransition:direction forView:self.view cache:NO];
    //动画结束
    [UIView commitAnimations];
}

- (void)sameCode{
    self.weiboButton.alpha = 1;
    self.QQButton.alpha = 1;
    self.WechatButton.alpha = 1;
    self.bottomLabel.alpha = 1;
    self.forgetAndAuth.alpha = 1;
    self.changePwdBtn.alpha = 0;
    self.login.alpha = 1;
    self.phoneNum.secureTextEntry = NO;
    self.phoneRegist.alpha = 1;
}

//不同的模式显示不同的界面
- (void)changeModelHidden{
    [self userInteractionIsAllow:YES];
    switch (self.currentStyle) {
        case XYLoginViewStyleLogin:
            [self sameCode];
            self.phoneNum.placeholder = @"请输入手机号";
            self.pwdAndAuth.secureTextEntry = YES;
            self.registPwd.alpha = 0;
            [self.forgetAndAuth setTitle:@"忘记密码?" forState:UIControlStateNormal];
            self.pwdAndAuth.placeholder = @"请输入密码";
            [self.login setTitle:@"登录" forState:UIControlStateNormal];
            [self.phoneRegist setTitle:@"手机注册" forState:UIControlStateNormal];
            self.pwdAndAuth.keyboardType = UIKeyboardTypeDefault;
            if (self.lastStyle == XYLoginViewStyleRegister) {
                CGRect frame = self.login.frame;
                frame.origin.y -= 40;
                self.login.frame = frame;
            }
            break;
        case XYLoginViewStyleRegister:
            [self sameCode];
            self.registPwd.alpha = 0.5;
            self.pwdAndAuth.secureTextEntry = NO;
            [self.forgetAndAuth setTitle:@"获取验证码" forState:UIControlStateNormal];
            self.pwdAndAuth.placeholder = @"请输入验证码";
            [self.login setTitle:@"注册" forState:UIControlStateNormal];
            [self.phoneRegist setTitle:@"返回登录" forState:UIControlStateNormal];
            self.pwdAndAuth.keyboardType = UIKeyboardTypeNumberPad;
            if (self.lastStyle != XYLoginViewStyleRegister) {
                CGRect frame = self.login.frame;
                frame.origin.y += 40;
                self.login.frame = frame;
            }
            break;
        case XYLoginViewStyleForget:
            self.phoneNum.placeholder = @"请输入手机号";
            self.pwdAndAuth.secureTextEntry = NO;
            [self.forgetAndAuth setTitle:@"获取验证码" forState:UIControlStateNormal];
            self.pwdAndAuth.placeholder = @"请输入验证码";
            [self.login setTitle:@"提交" forState:UIControlStateNormal];
            [self.phoneRegist setTitle:@"返回登录" forState:UIControlStateNormal];
            self.weiboButton.alpha = 0;
            self.QQButton.alpha = 0;
            self.WechatButton.alpha = 0;
            self.bottomLabel.alpha = 0;
            if (self.lastStyle == XYLoginViewStyleRegister) {
                CGRect frame = self.login.frame;
                frame.origin.y -= 40;
                self.login.frame = frame;
            }
            break;
        case XYLoginViewStyleChangePassword:
            self.weiboButton.alpha = 0;
            self.QQButton.alpha = 0;
            self.WechatButton.alpha = 0;
            self.bottomLabel.alpha = 0;
            self.forgetAndAuth.alpha = 0;
            self.phoneNum.placeholder = @"请输入旧密码";
            self.phoneNum.secureTextEntry = YES;
            self.pwdAndAuth.placeholder = @"请输入新密码";
            self.pwdAndAuth.keyboardType = UIKeyboardTypeDefault;
            self.pwdAndAuth.secureTextEntry = YES;
            self.registPwd.placeholder = @"请再次输入新密码";
            self.registPwd.alpha = 0.5;
            self.login.alpha = 0;
            self.deformation.alpha = 0;
            self.phoneRegist.alpha = 0;
            self.changePwdBtn.alpha = 1;
            break;
    }
}

- (IBAction)changePwd:(id)sender{
    // 其他按钮的交互取消
    [self userInteractionIsAllow:NO];
    [self startLoading:sender];
    //延时执行点击后操作，为确保动画完成
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![self.phoneNum.text isEqualToString:[[NSUserDefaults standardUserDefaults]objectForKey:@"pwd"]]) {
            //这里的pwd为存储的本地密码，因为只有登录成功才能进行密码修改功能，所以本地密码一定是正确的
            [SVProgressHUD showErrorWithStatus:@"旧密码不正确"];
            [self showLogin:self.changePwdBtn];
            return;
        }
        if ([self.pwdAndAuth.text isEqualToString:self.registPwd.text]) {
#warning needTODO:连接后台，修改密码代码
        }else{
            [SVProgressHUD showErrorWithStatus:@"两次密码不一致"];
            [self showLogin:self.changePwdBtn];
        }
    });
}

//翻转隐藏不必要的控件
- (void)hiddenSubviews:(BOOL)hidden duration:(NSInteger)duration{
    if (hidden) {
        //相应名字修改
        [UIView animateWithDuration:duration animations:^{
            self.pwdAndAuth.secureTextEntry = NO;
            [self.forgetAndAuth setTitle:@"获取验证码" forState:UIControlStateNormal];
            self.pwdAndAuth.placeholder = @"请输入验证码";
            [self.login setTitle:@"提交" forState:UIControlStateNormal];
            [self.phoneRegist setTitle:@"返回登录" forState:UIControlStateNormal];
            self.weiboButton.alpha = 0;
            self.QQButton.alpha = 0;
            self.WechatButton.alpha = 0;
            self.bottomLabel.alpha = 0;
        }];
    }
    else {
        [UIView animateWithDuration:duration animations:^{
            self.pwdAndAuth.secureTextEntry = YES;
            [self.forgetAndAuth setTitle:@"忘记密码?" forState:UIControlStateNormal];
            self.pwdAndAuth.placeholder = @"请输入密码";
            [self.login setTitle:@"登录" forState:UIControlStateNormal];
            [self.phoneRegist setTitle:@"手机注册" forState:UIControlStateNormal];
            self.weiboButton.alpha = 1;
            self.QQButton.alpha = 1;
            self.WechatButton.alpha = 1;
            self.bottomLabel.alpha = 1;
        }];
    }
}

//微博登录
- (IBAction)weboLogin:(id)sender {
    
}

//QQ登录
- (IBAction)qqLogin:(id)sender {
    
}

//微信登录
- (IBAction)wechatLogin:(id)sender {
    
}

- (void)getUserInfoForPlatform:(NSInteger)platformType
{
#warning needTODO:第三方登录
    [SVProgressHUD showWithStatus:@"正在登录"];
    
#warning needTODO:向服务器发送注册登录信息
    
}

// 登录成功处理
- (void)loginSuccess {
    
    [SVProgressHUD showSuccessWithStatus:@"登录成功"];
    //清空文本框内容
    self.phoneNum.text = @"";
    self.pwdAndAuth.text = @"";
    self.registPwd.text = @"";
    [self.deformation stopLoading];
    self.deformation.alpha = 0;
    //2.发送通知外界更新
    [[NSNotificationCenter defaultCenter]postNotificationName:kLoginSuccessNotification object:self];
    //3.退出该窗口
    [self backToSuperVC:nil];
}

//各类按钮点击功能开关
- (void)userInteractionIsAllow:(BOOL)allow{
    self.weiboButton.userInteractionEnabled = allow;
    self.QQButton.userInteractionEnabled = allow;
    self.WechatButton.userInteractionEnabled = allow;
    self.phoneRegist.userInteractionEnabled = allow;
    self.forgetAndAuth.userInteractionEnabled = allow;
}

#pragma mark -- textFiledDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == self.phoneNum){
        [self.pwdAndAuth becomeFirstResponder];
        return YES;
    }
    [textField resignFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self login:nil];
    });
    return YES;
}


#pragma mark -- Login actions

- (void)onLogin {
    __weak typeof(self) weakSelf = self;
    [XYAccountAuth loginWithMobile:self.phoneNum.text password:self.pwdAndAuth.text completionHandler:^(NSURLSessionDataTask * _Nonnull task, XYUser * _Nullable user, NSError * _Nullable error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            [weakSelf showLogin:weakSelf.login];//回收动画，回到原型
        }
        else {
            [weakSelf loginSuccess];
        }
    }];
}
@end
