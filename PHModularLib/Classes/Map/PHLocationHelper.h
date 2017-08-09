//
//  PHLocationHelper.h
//  App
//
//  Created by 項普華 on 2017/6/18.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PHTools.h"
#import "PHMacro.h"

typedef NS_ENUM(NSUInteger, PHAddressLevel) {
    PHAddressLevelCountry = 1,//国家
    PHAddressLevelProvince,//省
    PHAddressLevelCity,//城市
    PHAddressLevelArea,//区
    PHAddressLevelRoad,//道路
    PHAddressLevelName,//名称
};

typedef void(^PHAddressDecode)(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks);


@interface PHLocationHelper : NSObject<CLLocationManagerDelegate>

PH_ShareInstanceHeader(PHLocationHelper);

/**
 当前地址
 */
@property (nonatomic, strong, readonly) NSString *currentAddress;
/**
 当前位置
 */
@property (nonatomic, strong, readonly) CLLocation *currentLocation;


/**
 初始化定位设置 定位成功以后立即关闭定位
 */
+ (void)ph_locationManager;
/**
 开始定位
 */
+ (void)ph_startLocation;

/**
 停止定位
 */
+ (void)ph_stopLocation;


//根据placemark读取地址 level显示地址的级别
+ (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
                             level:(PHAddressLevel)level;
/**
 根据地址计算经纬度    ‼️‼️‼️‼️‼️一分钟内发送请求的次数不能超过50次   否则解析失败

 @param address 地址
 @param completion 经纬度
 */
+ (void)coordinate2DfromAddress:(NSString *)address
              completionHandler:(PHAddressDecode)completion;

/**
 根据经纬度计算地址   ‼️‼️‼️‼️‼️一分钟内发送请求的次数不能超过50次   否则解析失败

 @param coordinate2D 经纬度
 @param completion 地址
 */
+ (void)addressFromCoorinate2D:(CLLocationCoordinate2D)coordinate2D
             completionHandler:(PHAddressDecode)completion;





#pragma mark -- 导航参数

PH_AssignProperty(CLLocationCoordinate2D fromCoordinate2D);
PH_AssignProperty(CLLocationCoordinate2D toCoordinate2D);
PH_StringProperty(fromAddress);
PH_StringProperty(toAddress);
/**
 导航
 */
- (void)ph_navigation;




@end
