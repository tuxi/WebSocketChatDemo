//
//  XYWeakTimerTargetObj.m
//  WebSocketChatDemo
//
//  Created by swae on 2019/8/10.
//  Copyright © 2019 xiaoyuan. All rights reserved.
//

#import "XYWeakTimerTargetObj.h"

@implementation XYWeakTimerTargetObj

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo {
    
    XYWeakTimerTargetObj *obj = [[self alloc] init];
    obj.target = aTarget;
    obj.selector = aSelector;
    return [NSTimer scheduledTimerWithTimeInterval:ti target:obj selector:@selector(fire:) userInfo:userInfo repeats:yesOrNo];
}

- (void)fire:(id)obj {
    [self.target performSelector:self.selector withObject:obj];
}

@end
