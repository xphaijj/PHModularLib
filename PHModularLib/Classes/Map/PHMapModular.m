//
//  PHMapModular.m
//  App
//
//  Created by 項普華 on 2017/7/23.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHMapModular.h"
#import "PHMacro.h"
#import <BaiduMapKit/BaiduMapAPI_Base/BMKMapManager.h>
#import "PHSystemModel.h"


@interface PHMapModular ()<BMKGeneralDelegate> {
    BMKMapManager *mapManager;
}
@end

@implementation PHMapModular

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    mapManager = [[BMKMapManager alloc] init];
    BOOL ret = [mapManager start:[PHKeyConfig shareInstance].baidu_map_key generalDelegate:self];
    if (!ret) {
        PHLogError(@"百度地图初始化失败");
    }
    
    return YES;
}

/**
 *返回网络错误
 *@param iError 错误号
 */
- (void)onGetNetworkState:(int)iError {
    if (iError != 0) {
        PHLogError(@"地图注册失败 %d", iError);
    }
}

/**
 *返回授权验证错误
 *@param iError 错误号 : 为0时验证通过，具体参加BMKPermissionCheckResultCode
 */
- (void)onGetPermissionState:(int)iError {
    if (iError != 0) {
        PHLogError(@"地图注册失败 %d", iError);
    }
}



@end
