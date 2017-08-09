//
//  PHLocationHelper.m
//  App
//
//  Created by 項普華 on 2017/6/18.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHLocationHelper.h"
#import "PHLocationProtocol.h"
#import "NSMutableString+PHUtils.h"
#import <RMUniversalAlert.h>
#import <MapKit/MapKit.h>

#define DecodeQueue @"PHLocationHelperDecodeQueue"


static bool CLLocationCoordinate2DIsEqual(CLLocationCoordinate2D coor1, CLLocationCoordinate2D coor2) {
    return (ABS(coor1.latitude-coor2.latitude)<0.01 && ABS(coor1.longitude-coor2.longitude));
}

static CLLocationCoordinate2D LocationCoordinate2DIsValid(CLLocationCoordinate2D coor) {
    if (!CLLocationCoordinate2DIsValid(coor)) {
        coor = [PHLocationHelper shareInstance].currentLocation.coordinate;
    }
    if (!CLLocationCoordinate2DIsValid(coor)) {
        coor = CLLocationCoordinate2DMake(39.8838064,116.4002145);//天安门地址
    }
    return coor;
}

static NSString *addressIsValid(NSString *address) {
    if (!PH_CheckString(address)) {
        address = @"我的位置";
    }
    return address;
}


@interface PHNavigationModel : NSObject

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *title;

@end

@implementation PHNavigationModel

@end


@interface PHLocationHelper() {
    NSString *_fromAddress;
    NSString *_toAddress;
}

#pragma mark -- 定位相关
@property (nonatomic, strong) CLLocationManager *locationManager;

/**
 地址反向解析协议
 */
@property (nonatomic, strong) CLGeocoder *geocoder;

/**
 group
 */
@property (nonatomic, strong) dispatch_group_t geoGroup;
/**
 地址解析队列
 */
@property (nonatomic, strong) dispatch_queue_t geoQueue;
/**
 信号量
 */
@property (nonatomic, strong) dispatch_semaphore_t geoSemaphore;

/**
 保持一直定位
 */
@property (nonatomic, assign) BOOL keepLocation;//

/**
 支持导航的地图
 */
@property (nonatomic, strong) NSMutableArray *supportMaps;

@end


@implementation PHLocationHelper

PH_ShareInstance(PHLocationHelper);

- (void)ph_init {
}

- (dispatch_queue_t)geoQueue {
    if (!_geoQueue) {
        _geoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create([DecodeQueue UTF8String], DISPATCH_QUEUE_PRIORITY_DEFAULT);
    }
    return _geoQueue;
}

- (dispatch_group_t)geoGroup {
    if (!_geoGroup) {
        _geoGroup = dispatch_group_create();
    }
    return _geoGroup;
}

- (dispatch_semaphore_t)geoSemaphore {
    if (!_geoSemaphore) {
        _geoSemaphore = dispatch_semaphore_create(1);
    }
    return _geoSemaphore;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 100;
    }
    return _locationManager;
}

- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

/**
 初始化定位设置
 */
+ (void)ph_locationManager {
    if ([CLLocationManager locationServicesEnabled]) {
        [[PHLocationHelper shareInstance].locationManager requestWhenInUseAuthorization];
        [[PHLocationHelper shareInstance].locationManager requestAlwaysAuthorization];
        [PHLocationHelper shareInstance].keepLocation = NO;
        [[PHLocationHelper shareInstance].locationManager startUpdatingLocation];
    }
    else {
        PH_ShowTips(@"为了更好的体验App，请打开定位功能");
    }
}

/**
 开始定位
 */
+ (void)ph_startLocation {
    [PHLocationHelper shareInstance].keepLocation = YES;
    [[PHLocationHelper shareInstance].locationManager startUpdatingLocation];
}

/**
 停止定位
 */
+ (void)ph_stopLocation {
    [PHLocationHelper shareInstance].keepLocation = NO;
    [[PHLocationHelper shareInstance].locationManager stopUpdatingLocation];
}


//根据placemark读取地址 level显示地址的级别
+ (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
                             level:(PHAddressLevel)level {
    NSMutableString *result = [[NSMutableString alloc] init];
    switch (level) {
        case PHAddressLevelCountry: {
            [result appendString:placemark.country];
        }
        case PHAddressLevelProvince: {
            [result appendString:placemark.administrativeArea];
            if (![placemark.administrativeArea isEqualToString:placemark.subAdministrativeArea]) {
                [result appendString:placemark.subAdministrativeArea];
            }
        }
        case PHAddressLevelCity: {
            [result appendString:placemark.locality];
            if (![placemark.locality isEqualToString:placemark.subLocality]) {
                [result appendString:placemark.subLocality];
            }
        }
        case PHAddressLevelArea: {
            [result appendString:placemark.thoroughfare];
        }
        case PHAddressLevelRoad: {
            if (!(level>PHAddressLevelRoad && [placemark.thoroughfare isEqualToString:placemark.subThoroughfare])) {
                [result appendString:placemark.subThoroughfare];
            }
        }
        case PHAddressLevelName: {
            [result appendString:placemark.name];
        }
    }
    if (!PH_CheckString(result) && level!=PHAddressLevelCountry) {
        return [PHLocationHelper addressFromPlacemark:placemark level:level-1];
    }
    return result;
}

/**
 根据地址计算经纬度
 
 @param address 地址
 @param completion 经纬度
 */
+ (void)coordinate2DfromAddress:(NSString *)address
              completionHandler:(PHAddressDecode)completion {
    [[PHLocationHelper shareInstance] coordinate2DfromAddress:address completionHandler:completion];
}

- (void)coordinate2DfromAddress:(NSString *)address
              completionHandler:(PHAddressDecode)completion {
    dispatch_group_enter(self.geoGroup);
    dispatch_group_async(self.geoGroup, self.geoQueue, ^{
        dispatch_semaphore_wait(self.geoSemaphore, DISPATCH_TIME_FOREVER);
        __block PHAddressDecode success = completion;
        [[PHLocationHelper shareInstance].geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            dispatch_semaphore_signal(self.geoSemaphore);
            if (placemarks.count>0 && error == nil) {
                CLPlacemark *place = [placemarks firstObject];
                if (success) {
                    success(place.name, place.location.coordinate, placemarks);
                }
            } else {
                PHLogError(@"地址解析错误 %@", error);
            }
        }];
        dispatch_group_leave(self.geoGroup);
    });
}

/**
 根据经纬度计算地址
 
 @param coordinate2D 经纬度
 @param completion 地址
 */
+ (void)addressFromCoorinate2D:(CLLocationCoordinate2D)coordinate2D
             completionHandler:(PHAddressDecode)completion {
    if (!CLLocationCoordinate2DIsValid(coordinate2D)) {
        PHLogError(@"传入经纬度异常 lat=%f lon=%f", coordinate2D.latitude, coordinate2D.longitude);
        return;
    }
    [[PHLocationHelper shareInstance] addressFromCoorinate2D:coordinate2D completionHandler:completion];
}

- (void)addressFromCoorinate2D:(CLLocationCoordinate2D)coordinate2D
             completionHandler:(PHAddressDecode)completion {
    dispatch_group_enter(self.geoGroup);
    dispatch_group_async(self.geoGroup, self.geoQueue, ^{
        dispatch_semaphore_wait(self.geoSemaphore, DISPATCH_TIME_FOREVER);
        __block PHAddressDecode success = completion;
        [self.geocoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude] completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            dispatch_semaphore_signal(self.geoSemaphore);
            if (placemarks.count>0 && error == nil) {
                CLPlacemark *place = [placemarks firstObject];
                NSString *address = [PHLocationHelper addressFromPlacemark:place level:PHAddressLevelProvince];
                if (success) {
                    success(address, place.location.coordinate, placemarks);
                }
            }
            else {
                PHLogError(@"地址反向解析错误 %@", error);
            }
        }];
        dispatch_group_leave(self.geoGroup);
    });
}

#pragma mark -- address delegate

#pragma mark -- location delegate
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    id vc = PH_CurrentVC();
    if ([vc respondsToSelector:@selector(ph_location:oldLocation:)]) {
        [vc ph_location:newLocation oldLocation:oldLocation];
    }
    _currentLocation = newLocation;
    /*
     子类实现了address 协议才去反向地址方法
     */
    if ([vc respondsToSelector:@selector(ph_address:info:)]) {
        [PHLocationHelper addressFromCoorinate2D:_currentLocation.coordinate completionHandler:^(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks) {
            id vc = PH_CurrentVC();
            _currentAddress = address;
            if ([vc respondsToSelector:@selector(ph_address:info:)]) {
                [vc ph_address:self.currentAddress info:placemarks[0]];
            }
        }];
    }
    
    if (!self.keepLocation) {//定位成功以后立即关闭定位
        [PHLocationHelper ph_stopLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading {
}







#pragma mark -- 调用第三方导航
- (void)setFromCoordinate2D:(CLLocationCoordinate2D)fromCoordinate2D {
    if (!CLLocationCoordinate2DIsEqual(_fromCoordinate2D, fromCoordinate2D)) {
        _fromCoordinate2D = fromCoordinate2D;
        [PHLocationHelper addressFromCoorinate2D:fromCoordinate2D completionHandler:^(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks) {
            _fromAddress = [PHLocationHelper addressFromPlacemark:placemarks[0] level:PHAddressLevelCity];
        }];
    }
}

- (void)setToCoordinate2D:(CLLocationCoordinate2D)toCoordinate2D {
    if (!CLLocationCoordinate2DIsEqual(_toCoordinate2D, toCoordinate2D)) {
        _toCoordinate2D = toCoordinate2D;
        [PHLocationHelper addressFromCoorinate2D:toCoordinate2D completionHandler:^(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks) {
            _toAddress = [PHLocationHelper addressFromPlacemark:placemarks[0] level:PHAddressLevelCity];
        }];
    }
}

- (void)setFromAddress:(NSString *)fromAddress {
    if (PH_CheckString(fromAddress) && ![_fromAddress isEqualToString:fromAddress]) {
        _fromAddress = fromAddress;
        [PHLocationHelper coordinate2DfromAddress:fromAddress completionHandler:^(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks) {
            _fromCoordinate2D = coordinate2D;
        }];
    }
}

- (void)setToAddress:(NSString *)toAddress {
    if (PH_CheckString(toAddress) && ![_toAddress isEqualToString:toAddress]) {
        _toAddress = toAddress;
        [PHLocationHelper coordinate2DfromAddress:toAddress completionHandler:^(NSString *address, CLLocationCoordinate2D coordinate2D, NSArray<CLPlacemark *> *placemarks) {
            _toCoordinate2D = coordinate2D;
        }];
    }
}

- (NSString *)fromAddress {
    if (!PH_CheckString(_fromAddress)) {
        return @"";
    }
    return _fromAddress;
}

- (NSString *)toAddress {
    if (!PH_CheckString(_toAddress)) {
        return @"";
    }
    return _toAddress;
}


/**
 导航
 */
- (void)ph_navigation {
    [RMUniversalAlert showActionSheetInViewController:PH_CurrentVC() withTitle:nil message:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:self.supportMaps popoverPresentationControllerBlock:^(RMPopoverPresentationController * _Nonnull popover) {
    } tapBlock:^(RMUniversalAlert * _Nonnull alert, NSInteger buttonIndex) {
        if (buttonIndex==2) {
            [self appleMap];
        } else if (buttonIndex>2) {
            NSString *str = self.supportMaps[buttonIndex-2];
            NSString *uri = @"";
            if ([str isEqualToString:@"百度地图"]) {
                uri = [self baiduURI];
            } else if ([str isEqualToString:@"高德地图"]) {
                uri = [self gaodeURI];
            } else if ([str isEqualToString:@"谷歌地图"]) {
                uri = [self googleURI];
            } else if ([str isEqualToString:@"腾讯地图"]) {
                uri = [self qqURI];
            }
            if (PH_CheckString(uri)) {
                PHLog(@"调用第三方导航%@   经纬度=%f,%f 地址=%@  经纬度=%f,%f 地址=%@", uri, self.fromCoordinate2D.latitude, self.fromCoordinate2D.longitude, self.fromAddress, self.toCoordinate2D.latitude, self.toCoordinate2D.longitude, self.toAddress);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:uri]];
            }
        }
    }];
}



- (NSMutableArray *)supportMaps {
    if (!_supportMaps) {
        _supportMaps = [[NSMutableArray alloc] init];
        {
            [_supportMaps addObject:@"苹果地图"];
        }
        
        //百度地图
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
            [_supportMaps addObject:@"百度地图"];
        }
        
        //高德地图
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
            [_supportMaps addObject:@"高德地图"];
        }
        
        //谷歌地图
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
            [_supportMaps addObject:@"谷歌地图"];
        }
        
        //腾讯地图
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
            [_supportMaps addObject:@"腾讯地图"];
        }
    }
    
    return _supportMaps;
}

- (NSString *)baiduURI {
    NSString *startLocation = [NSString stringWithFormat:@"name:%@|latlng:%f,%f", self.fromAddress, self.fromCoordinate2D.latitude, self.fromCoordinate2D.longitude];
    NSString *endLocation = [NSString stringWithFormat:@"name:%@|latlng:%f,%f", self.toAddress, self.toCoordinate2D.latitude, self.toCoordinate2D.longitude];
    return [[NSString stringWithFormat:@"baidumap://map/direction?origin=%@&destination=%@&mode=driving&src=%@", startLocation, endLocation, PH_AppName] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
}

- (NSString *)gaodeURI {
    NSString *startLocation = [NSString stringWithFormat:@"slat=%f&slon=%f&sname=%@", self.fromCoordinate2D.latitude, self.fromCoordinate2D.longitude, self.fromAddress];
    NSString *endLocation = [NSString stringWithFormat:@"dlat=%f&dlon=%f&dname=%@", self.toCoordinate2D.latitude, self.toCoordinate2D.longitude, self.toAddress];
    return [[NSString stringWithFormat:@"iosamap://path?sourceApplication=%@&backScheme=%@&sid=BGVIS1&%@&did=BGVIS2&%@&dev=0&t=0", PH_AppName, PH_URL_SCHEME, startLocation, endLocation]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
}

- (NSString *)googleURI {
    NSString *startLocation = [NSString stringWithFormat:@"saddr=%@&sll=%f,%f", self.fromAddress, self.fromCoordinate2D.latitude, self.fromCoordinate2D.longitude];
    NSString *endLocation = [NSString stringWithFormat:@"daddr=%@&dll=%f,%f", self.toAddress, self.toCoordinate2D.latitude, self.toCoordinate2D.longitude];
    return [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&%@&%@&directionsmode=driving", PH_AppName, PH_URL_SCHEME, startLocation, endLocation] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
}

- (NSString *)qqURI{
    
    
    return @"";//[[NSString stringWithFormat:@"qqmap://map/routeplan?%@&%@&type=drive&coord_type=1&policy=0", startLocation, endLocation]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
}

- (void)appleMap {
    MKMapItem *currentLoc = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.fromCoordinate2D addressDictionary:@{@"name":self.fromAddress}]];
    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.toCoordinate2D addressDictionary:@{@"name":self.toAddress}]];
    NSArray *items = @[currentLoc,toLocation];
    NSDictionary *dic = @{
                          MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving,
                          MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),
                          MKLaunchOptionsShowsTrafficKey : @(YES)
                          };
    
    [MKMapItem openMapsWithItems:items launchOptions:dic];
}


@end
