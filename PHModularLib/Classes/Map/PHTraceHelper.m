//
//  PHTraceHelper.m
//  App
//
//  Created by 項普華 on 2017/7/29.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHTraceHelper.h"
#import "PHMacro.h"
#import "PHTools.h"
#import <BaiduTraceSDK/BaiduTraceSDK.h>
#import <RMUniversalAlert.h>

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#define YYPushMessageNotificationIdentifier @"YYPushMessageNotificationIdentifier"


typedef NS_ENUM(NSUInteger, ServiceStatus) {
    ServiceStatusSuccess = 100,
    ServiceStatusFailed,
    ServiceStatusProgess,
};

typedef NS_ENUM(NSUInteger, ServiceOperationType) {
    PH_SERVICE_OPERATION_TYPE_START_SERVICE,
    PH_SERVICE_OPERATION_TYPE_STOP_SERVICE,
    PH_SERVICE_OPERATION_TYPE_START_GATHER,
    PH_SERVICE_OPERATION_TYPE_STOP_GATHER,
};

@interface PHServiceParam() {
}

@property (nonatomic, assign) ServiceStatus serviceStatus;
@property (nonatomic, strong) NSTimer *timer;
//信号量
@property (nonatomic, strong) dispatch_semaphore_t serviceSemaphore;
@property (nonatomic, copy)   NSString *entityName;

@end

@implementation PHServiceParam

- (instancetype)init {
    self = [super init];
    if (self) {
        // 配置默认值
        self.serviceStatus = ServiceStatusFailed;
        self.gatherInterval = 5;
        self.packInterval = 30;
        self.activityType = CLActivityTypeAutomotiveNavigation;
        self.desiredAccuracy = kCLLocationAccuracyBest;
        self.distanceFilter = kCLDistanceFilterNone;
        self.serviceSemaphore = dispatch_semaphore_create(0);
        if (PH_CheckString(ENTITY_NAME)) {
            self.entityName = ENTITY_NAME;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wundeclared-selector"
        self.timer = [NSTimer timerWithTimeInterval:self.gatherInterval target:[PHTraceHelper shareInstance] selector:@selector(queryLatestPosition) userInfo:nil repeats:YES];
#pragma clang diagnostic pop
    }
    return self;
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
}

@end


@interface PHTraceHelper ()<BTKTraceDelegate, BTKTrackDelegate, CLLocationManagerDelegate> {
}

@property (nonatomic, strong) PHServiceParam *currentService;

@end

@implementation PHTraceHelper

PH_ShareInstance(PHTraceHelper);

- (void)ph_init {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceOperationResultHandler:) name:YYServiceOperationResultNotification object:nil];
}

- (void)dealloc {
    [self ph_dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YYServiceOperationResultNotification object:nil];
}

- (void)ph_dealloc {
    [self.currentService stop];
}

- (PHServiceParam *)currentService {
    if (!_currentService) {
        _currentService = [[PHServiceParam alloc] init];
    }
    return _currentService;
}

//开始检测
+ (void)start {
    [[PHTraceHelper shareInstance] startWithName:ENTITY_NAME];
}
//结束检测
+ (void)stop {
    [[PHTraceHelper shareInstance] stop];
}

//开始检测 根据name生成对象
+ (void)startWithName:(NSString *)name {
    [[PHTraceHelper shareInstance] startWithName:name];
}

//开始检测 根据name生成对象
- (void)startWithName:(NSString *)name {
    if (_currentService == nil) {
        self.currentService.entityName = name;
        switch (self.currentService.serviceStatus) {
            case ServiceStatusSuccess: {
                PHLogError(@"鹰眼功能已经启动");
            }
                break;
            case ServiceStatusProgess: {
                PHLogWarn(@"鹰眼功能正在启动");
            }
                break;
            case ServiceStatusFailed: {
                self.currentService.serviceStatus = ServiceStatusProgess;
                [[NSRunLoop currentRunLoop] addTimer:self.currentService.timer forMode:NSDefaultRunLoopMode];
                self.currentService.serviceSemaphore = dispatch_semaphore_create(0);
                BTKServiceOption *infoOption = [[BTKServiceOption alloc] initWithAK:Baidu_AK mcode:Baidu_MCODE serviceID:Baidu_serviceID keepAlive:Baidu_keepAlive];
                [[BTKAction sharedInstance] initInfo:infoOption];
                // 开启服务
                BTKStartServiceOption *startServiceOption = [[BTKStartServiceOption alloc] initWithEntityName:self.currentService.entityName];
                PHLog(@"开启服务 %@", self.currentService.entityName);
                dispatch_async(PH_GlobalQueue, ^{
                    [[BTKAction sharedInstance] startService:startServiceOption delegate:self];
                });
                
                dispatch_semaphore_wait(self.currentService.serviceSemaphore, DISPATCH_TIME_FOREVER);
                // 开始采集
                PHLog(@"开始采集");
                dispatch_async(PH_GlobalQueue, ^{
                    [[BTKAction sharedInstance] startGather:self];
                });
                [self resumeTimer];
            }
                break;
        }
    } else {
        PHLogError(@"后台已经存在一个任务，请先取消");
//        PH_Weak(self);
//        [RMUniversalAlert showAlertInViewController:PH_CurrentVC() withTitle:@"提示"  message:@"已经有一个服务，是否重启？" cancelButtonTitle:@"否" destructiveButtonTitle:@"是" otherButtonTitles:nil tapBlock:^(RMUniversalAlert * _Nonnull alert, NSInteger buttonIndex) {
//            PH_Strong(self);
//            if (buttonIndex == 1) {
//                [self stop];
//                [self startWithName:name];
//            }
//        }];
    }
    
}
//结束检测 根据name停止对象
- (void)stop {
    switch (self.currentService.serviceStatus) {
        case ServiceStatusFailed: {
            PHLogError(@"鹰眼功能已经停止");
        }
            break;
        case ServiceStatusProgess: {
            PHLogWarn(@"鹰眼功能正在停止");
        }
            break;
        case ServiceStatusSuccess: {
            self.currentService.serviceStatus = ServiceStatusProgess;
            [self pauseTimer];
            dispatch_async(PH_GlobalQueue, ^{
                [[BTKAction sharedInstance] stopGather:self];
                [[BTKAction sharedInstance] stopService:self];
            });
            [self ph_dealloc];
        }
            break;
    }
    self.currentService = nil;
}

-(void)onQueryTrackLatestPoint:(NSData *)response {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:nil];
    if (nil == dict) {
        PHLog(@"Entity List查询格式转换出错");
        return;
    }
    if (0 != [dict[@"status"] intValue]) {
        PHLog(@"实时位置查询返回错误");
        return;
    }
    
    NSDictionary *latestPoint = dict[@"latest_point"];
    double latitude = [latestPoint[@"latitude"] doubleValue];
    double longitude = [latestPoint[@"longitude"] doubleValue];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    double horizontalAccuracy = [latestPoint[@"radius"] doubleValue];
    double loctime = [latestPoint[@"loc_time"] doubleValue];
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:loctime];
    CLLocation *latestLocation = [[CLLocation alloc] initWithCoordinate:coordinate altitude:0 horizontalAccuracy:horizontalAccuracy verticalAccuracy:0 timestamp:timestamp];
}

-(void)pauseTimer {
    [self.currentService.timer invalidate];
    self.currentService.timer = nil;
}

-(void)resumeTimer {
    if (self.currentService.timer) {
        [self.currentService.timer invalidate];
        self.currentService.timer = nil;
    }
    self.currentService.timer = [NSTimer scheduledTimerWithTimeInterval:self.currentService.gatherInterval target:self selector:@selector(queryLatestPosition) userInfo:nil repeats:YES];
}

#pragma mark - event response
-(void)serviceOperationResultHandler:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    ServiceOperationType type = (ServiceOperationType)[info[@"type"] unsignedIntValue];
    //    NSString *title = info[@"title"];
    //    NSString *message = info[@"message"];
    switch (type) {
        case PH_SERVICE_OPERATION_TYPE_START_SERVICE:
            break;
        case PH_SERVICE_OPERATION_TYPE_STOP_SERVICE:
            break;
        case PH_SERVICE_OPERATION_TYPE_START_GATHER:
            break;
        case PH_SERVICE_OPERATION_TYPE_STOP_GATHER:
            break;
        default:
            break;
    }
}

/// 本方法查询实时位置，只是为了在轨迹服务的控制页面展示当前的位置，所以这里不设置纠偏选项。
/// 关于SDK中的queryTrackLatestPointWith方法，在其他页面中有详细介绍。
-(void)queryLatestPosition {
    dispatch_async(PH_GlobalQueue, ^{
        BTKQueryTrackLatestPointRequest *request = [[BTKQueryTrackLatestPointRequest alloc] initWithEntityName:self.currentService.entityName processOption:nil outputCootdType:BTK_COORDTYPE_BD09LL serviceID:Baidu_serviceID tag:0];
        [[BTKTrackAction sharedInstance] queryTrackLatestPointWith:request delegate:self];
    });
}

#pragma mark - BTKTraceDelegate
-(void)onStartService:(BTKServiceErrorCode)error {
    // 维护状态标志
    if (error == BTK_START_SERVICE_SUCCESS || error == BTK_START_SERVICE_SUCCESS_BUT_OFFLINE) {
        PHLog(@"轨迹服务开启成功");
    } else {
        PHLog(@"轨迹服务开启失败");
    }
    // 构造广播内容
    NSString *title = nil;
    NSString *message = nil;
    switch (error) {
        case BTK_START_SERVICE_SUCCESS:
            title = @"轨迹服务开启成功";
            message = @"成功登录到服务端";
            break;
        case BTK_START_SERVICE_SUCCESS_BUT_OFFLINE:
            title = @"轨迹服务开启成功";
            message = @"当前网络不畅，未登录到服务端。网络恢复后SDK会自动重试";
            break;
        case BTK_START_SERVICE_PARAM_ERROR:
            title = @"轨迹服务开启失败";
            message = @"参数错误,点击右上角设置按钮设置参数";
            break;
        case BTK_START_SERVICE_INTERNAL_ERROR:
            title = @"轨迹服务开启失败";
            message = @"SDK服务内部出现错误";
            break;
        case BTK_START_SERVICE_NETWORK_ERROR:
            title = @"轨迹服务开启失败";
            message = @"网络异常";
            break;
        case BTK_START_SERVICE_AUTH_ERROR:
            title = @"轨迹服务开启失败";
            message = @"鉴权失败，请检查AK和MCODE等配置信息";
            break;
        case BTK_START_SERVICE_IN_PROGRESS:
            title = @"轨迹服务开启失败";
            message = @"正在开启服务，请稍后再试";
            break;
        case BTK_SERVICE_ALREADY_STARTED_ERROR:
            title = @"轨迹服务开启失败";
            message = @"已经成功开启服务，请勿重复开启";
            break;
        default:
            title = @"通知";
            message = @"轨迹服务开启结果未知";
            break;
    }
    NSDictionary *info = @{@"type":@(PH_SERVICE_OPERATION_TYPE_START_SERVICE),
                           @"title":title,
                           @"message":message,
                           };
    // 发送广播
    [[NSNotificationCenter defaultCenter] postNotificationName:YYServiceOperationResultNotification object:nil userInfo:info];
    dispatch_semaphore_signal(self.currentService.serviceSemaphore);
}

-(void)onStopService:(BTKServiceErrorCode)error {
    // 维护状态标志
    if (error == BTK_STOP_SERVICE_NO_ERROR) {
        PHLog(@"轨迹服务停止成功");
    } else {
        PHLog(@"轨迹服务停止失败");
    }
    // 构造广播内容
    NSString *title = nil;
    NSString *message = nil;
    switch (error) {
        case BTK_STOP_SERVICE_NO_ERROR:
            title = @"轨迹服务停止成功";
            message = @"SDK已停止工作";
            break;
        case BTK_STOP_SERVICE_NOT_YET_STARTED_ERROR:
            title = @"轨迹服务停止失败";
            message = @"还没有开启服务，无法停止服务";
            break;
        case BTK_STOP_SERVICE_IN_PROGRESS:
            title = @"轨迹服务停止失败";
            message = @"正在停止服务，请稍后再试";
            break;
        default:
            title = @"通知";
            message = @"轨迹服务停止结果未知";
            break;
    }
    NSDictionary *info = @{@"type":@(PH_SERVICE_OPERATION_TYPE_STOP_SERVICE),
                           @"title":title,
                           @"message":message,
                           };
    // 发送广播
    [[NSNotificationCenter defaultCenter] postNotificationName:YYServiceOperationResultNotification object:nil userInfo:info];
}

-(void)onStartGather:(BTKGatherErrorCode)error {
    // 维护状态标志
    if (error == BTK_START_GATHER_SUCCESS) {
        PHLog(@"开始采集成功");
        self.currentService.serviceStatus = ServiceStatusSuccess;
    } else {
        PHLog(@"开始采集失败");
    }
    // 构造广播内容
    NSString *title = nil;
    NSString *message = nil;
    switch (error) {
        case BTK_START_GATHER_SUCCESS:
            title = @"开始采集成功";
            message = @"开始采集成功";
            break;
        case BTK_GATHER_ALREADY_STARTED_ERROR:
            title = @"开始采集失败";
            message = @"已经在采集轨迹，请勿重复开始";
            break;
        case BTK_START_GATHER_BEFORE_START_SERVICE_ERROR:
            title = @"开始采集失败";
            message = @"开始采集必须在开始服务之后调用";
            break;
        case BTK_START_GATHER_LOCATION_SERVICE_OFF_ERROR:
            title = @"开始采集失败";
            message = @"没有开启系统定位服务";
            break;
        case BTK_START_GATHER_LOCATION_ALWAYS_USAGE_AUTH_ERROR:
            title = @"开始采集失败";
            message = @"没有开启后台定位权限";
            break;
        case BTK_START_GATHER_INTERNAL_ERROR:
            title = @"开始采集失败";
            message = @"SDK服务内部出现错误";
            break;
        default:
            title = @"通知";
            message = @"开始采集轨迹的结果未知";
            break;
    }
    NSDictionary *info = @{@"type":@(PH_SERVICE_OPERATION_TYPE_START_GATHER),
                           @"title":title,
                           @"message":message,
                           };
    // 发送广播
    [[NSNotificationCenter defaultCenter] postNotificationName:YYServiceOperationResultNotification object:nil userInfo:info];
}

-(void)onStopGather:(BTKGatherErrorCode)error {
    // 维护状态标志
    if (error == BTK_STOP_GATHER_NO_ERROR) {
        PHLog(@"停止采集成功");
        self.currentService.serviceStatus = ServiceStatusFailed;
    } else {
        PHLog(@"停止采集失败");
    }
    // 构造广播内容
    NSString *title = nil;
    NSString *message = nil;
    switch (error) {
        case BTK_STOP_GATHER_NO_ERROR:
            title = @"停止采集成功";
            message = @"SDK停止采集本设备的轨迹信息";
            break;
        case BTK_STOP_GATHER_NOT_YET_STARTED_ERROR:
            title = @"开始采集失败";
            message = @"还没有开始采集，无法停止";
            break;
        default:
            title = @"通知";
            message = @"停止采集轨迹的结果未知";
            break;
    }
    NSDictionary *info = @{@"type":@(PH_SERVICE_OPERATION_TYPE_STOP_GATHER),
                           @"title":title,
                           @"message":message,
                           };
    // 发送广播
    [[NSNotificationCenter defaultCenter] postNotificationName:YYServiceOperationResultNotification object:nil userInfo:info];
}

-(void)onGetPushMessage:(BTKPushMessage *)message {
    // 不是地理围栏的报警，不解析
    if (message.type != 0x03 && message.type != 0x04) {
        return;
    }
    BTKPushMessageFenceAlarmContent *content = (BTKPushMessageFenceAlarmContent *)message.content;
    NSString *fenceName = [NSString stringWithFormat:@"「%@」", content.fenceName];
    NSString *monitoredObject = [NSString stringWithFormat:@"「%@」", content.monitoredObject];
    NSString *action = nil;
    if (content.actionType == BTK_FENCE_MONITORED_OBJECT_ACTION_TYPE_ENTER) {
        action = @"进入";
    } else {
        action = @"离开";
    }
    NSString *fenceType = nil;
    if (message.type == 0x03) {
        fenceType = @"服务端围栏";
    } else {
        fenceType = @"客户端围栏";
    }
    // 通过触发报警的轨迹点，解析出触发报警的时间
    BTKFenceAlarmLocationPoint *currentPoint = content.currentPoint;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *alarmDate = [NSDate dateWithTimeIntervalSince1970:currentPoint.loctime];
    NSString *alarmDateStr = [dateFormatter stringFromDate:alarmDate];
    
    NSString *pushMessage = [NSString stringWithFormat:@"终端 %@ 在 %@ %@ %@%@", monitoredObject, alarmDateStr, action, fenceType, fenceName];
    PHLogError(@"带处理 推送消息: %@", pushMessage);
    // 简单起见，DEMO只处理iOS10以上的情况
    if (PH_iOS_VERSION >= 10.0) {
        // 发送本地通知
        UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];
        notificationContent.title = [NSString stringWithFormat:@"%@ 报警", fenceType];
        notificationContent.body = pushMessage;
        notificationContent.sound = [UNNotificationSound defaultSound];
        UNTimeIntervalNotificationTrigger *notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        NSString *idd = [NSString stringWithFormat:@"%@%@",YYPushMessageNotificationIdentifier, pushMessage];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:idd content:notificationContent trigger:notificationTrigger];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                PHLog(@"地理围栏报警通知发送失败: %@", error);
            } else {
                PHLog(@"通知发送成功");
                [UIApplication sharedApplication].applicationIconBadgeNumber += 1;
            }
        }];
    } else {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:YYPushMessageNotificationIdentifier object:pushMessage];
    }
}

@end
