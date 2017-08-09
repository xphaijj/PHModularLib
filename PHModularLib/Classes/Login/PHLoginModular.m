//
//  PHLoginHelper.m
//  App
//
//  Created by Alex on 2017/7/19.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHLoginModular.h"
#import "PHMacro.h"
#import "PHTools.h"

@implementation PHLoginModular

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initThirdParty];
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    return result;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url options:options];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    return result;
}

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url {
    BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
    if (!result) {
        // 其他如支付等SDK的回调
    }
    return result;
}

/**
 初始化第三方服务
 */
- (void)initThirdParty {
    /*********友盟***********/
    /* 打开调试日志 */
    [[UMSocialManager defaultManager] openLog:YES];
    /* 设置友盟appkey */
    [[UMSocialManager defaultManager] setUmSocialAppkey:USHARE_APPKEY];
    [self uMengConfig];
}

- (void)uMengConfig {
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:WECHAT_APPKEY appSecret:WECHAT_APPSECRET redirectURL:WECHAT_REDIRECT_URL];
}

/**
 *  授权并获取用户信息
 *  @param platformType 平台类型 @see UMSocialPlatformType
 *  @param completion   回调
 */
+ (void)getUserInfoWithPlatform:(UMSocialPlatformType)platformType
                     completion:(UMSocialRequestCompletionHandler)completion {
    [[UMSocialManager defaultManager] getUserInfoWithPlatform:platformType currentViewController:PH_CurrentVC() completion:completion];
}




@end
