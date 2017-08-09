//
//  PHLogHelper.h
//  App
//
//  Created by 項普華 on 2017/6/19.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PHMacro.h"

@interface PHLogHelper : NSObject

PH_ShareInstanceHeader(PHLogHelper);

/**
 开启日志管理系统
 */
+ (void)ph_startLogManager;

/**
 关闭日志管理系统
 */
+ (void)ph_stopLogManager;

@end
