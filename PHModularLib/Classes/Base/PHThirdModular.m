//
//  PHThirdModular.m
//  App
//
//  Created by Alex on 2017/7/21.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHThirdModular.h"
#import "PHMacro.h"
#import "PHTools.h"
#import <GDPerformanceView/GDPerformanceMonitor.h>

@implementation PHThirdModular

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initThirdParty];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
#ifdef DEBUG
    [[GDPerformanceMonitor sharedInstance] stopMonitoring];
#endif
}

- (void)initThirdParty {
#ifdef DEBUG
    [[GDPerformanceMonitor sharedInstance] startMonitoring];
    [[GDPerformanceMonitor sharedInstance] configureWithConfiguration:^(UILabel *textLabel) {
        [textLabel setBackgroundColor:[UIColor blackColor]];
        [textLabel setTextColor:[UIColor whiteColor]];
        [textLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    }];
#endif
}



@end
