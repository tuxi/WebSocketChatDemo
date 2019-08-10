//
//  ViewController.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "ViewController.h"
#import "XYLoginViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)login:(id)sender {
    
    [[XYLoginViewController sharedInstance] showWithStyle:XYLoginViewStyleLogin superController:self];
}

@end
