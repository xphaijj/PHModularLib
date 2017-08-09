//
//  PHModularManager.m
//  App
//
//  Created by Alex on 2017/7/19.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHModularManager.h"
#import "PHMacro.h"

static NSArray *modularsName;



@implementation PHModularManager

PH_ShareInstance(PHModularManager);

- (void)ph_init {
}

static NSMutableArray *modulars;

+ (void)load {
   modularsName = @[
                    @"PHLoginModular",
                    @"PHThirdModular",
                    @"PHThemeModular",
                    @"PHPushModular",
                    @"PHMapModular",
                    ];
    modulars = [[NSMutableArray alloc] init];
    for (NSString *className in modularsName) {
        Class cls = NSClassFromString(className);
        if (cls) {
            [modulars addObject:[[cls alloc] init]];
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application openURL:url options:options];
        }
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application handleOpenURL:url];
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls applicationWillResignActive:application];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls applicationDidEnterBackground:application];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls applicationWillEnterForeground:application];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls applicationDidBecomeActive:application];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls applicationWillTerminate:application];
        }
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application didFailToRegisterForRemoteNotificationsWithError:error];
        }
    }
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    for (id cls in modulars) {
        if ([cls respondsToSelector:_cmd]) {
            [cls application:application didReceiveRemoteNotification:userInfo];
        }
    }
}











@end
