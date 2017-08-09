//
//  PHLoginHelper.h
//  App
//
//  Created by Alex on 2017/7/19.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UMengUShare/UMSocialCore/UMSocialCore.h>

@interface PHLoginModular : NSObject

/**
 初始化第三方服务
 */
- (void)initThirdParty;

/**
 *  授权并获取用户信息
 *  @param platformType 平台类型 @see UMSocialPlatformType
 *  @param completion   回调
 */
+ (void)getUserInfoWithPlatform:(UMSocialPlatformType)platformType
                     completion:(UMSocialRequestCompletionHandler)completion;



@end
