//
//  XYSafeTimer.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYSafeTimer.h"

@implementation XYSafeTimer

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    
    XYSafeTimer *obj = [[self alloc] init];
    obj.target = aTarget;
    obj.selector = aSelector;
    return [NSTimer scheduledTimerWithTimeInterval:ti target:obj selector:@selector(fire:) userInfo:userInfo repeats:yesOrNo];
}

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block {
    
    return [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(handleBlock:) userInfo:[block copy] repeats:repeats];
}

- (void)handleBlock:(NSTimer *)timer {
    void (^block)(NSTimer *) = timer.userInfo;
    if (block) {
        block(timer);
    }
}

- (void)fire:(id)obj {
    IMP imp = [self.target methodForSelector:self.selector];
    void (*func)(id, SEL, id) = (void *)imp;
    if (func) {
        func(self.target, self.selector, obj);
    }
}

@end
