//
//  PHTraceHelper.h
//  App
//
//  Created by 項普華 on 2017/7/29.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PHMacro.h"

#define ENTITY_NAME [NSString stringWithFormat:@"%@_%@", PH_UUID, PH_BundleIdentifier]
#define LATEST_LOCATION @"latest_location"
// 填写你在API控制台申请的iOS类型的AK
#define Baidu_AK @"YYwQquxKctGYGaWFhniXs7EtG639klmY"
//填写你在API控制台申请iOS类型AK时指定的  Bundle Identifier
#define Baidu_MCODE PH_BundleIdentifier
// 填写你在鹰眼轨迹管理台创建的鹰眼服务对应的ID
#define Baidu_serviceID 146920
//是否一直保持后台运行
#define Baidu_keepAlive NO

#define YYServiceOperationResultNotification @"YYServiceOperationResultNotification"

@interface PHServiceParam : NSObject

@property (nonatomic, assign) NSUInteger gatherInterval;
@property (nonatomic, assign) NSUInteger packInterval;
@property (nonatomic, assign) CLActivityType activityType;
@property (nonatomic, assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic, assign) CLLocationDistance distanceFilter;

@end



//百度鹰眼功能
@interface PHTraceHelper : NSObject

PH_ShareInstanceHeader(PHTraceHelper);

//开始检测
+ (void)start;
//结束检测
+ (void)stop;

//开始检测 根据name生成对象
+ (void)startWithName:(NSString *)name;


@end
