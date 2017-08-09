//
//  PHLogHelper.m
//  App
//
//  Created by 項普華 on 2017/6/19.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHLogHelper.h"
#import "PHFileHelper.h"
#import <ReactiveObjC/ReactiveObjC.h>

@implementation PHLogHelper

PH_ShareInstance(PHLogHelper);

/**
 开启日志管理系统
 */
+ (void)ph_startLogManager {
    //创建日志管理路径
    [PHFileHelper createLogWithFilename:@"PHLog"];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:PH_VIEWAPPEAR object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        PHLog(@"收到了视图出现的通知 %@", x.object);
    }];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:PH_VIEWDISAPPEAR object:nil] subscribeNext:^(NSNotification * _Nullable x) {
        PHLog(@"收到了视图消失的通知 %@", x.object);
    }];
}

;

/**
 关闭日志管理系统
 */
+ (void)ph_stopLogManager {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PH_VIEWAPPEAR object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PH_VIEWDISAPPEAR object:nil];
}

@end
