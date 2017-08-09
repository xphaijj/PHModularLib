//
//  PHThemeModular.m
//  App
//
//  Created by 項普華 on 2017/7/22.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHThemeModular.h"
#import "PHMacro.h"
#import "PHTools.h"

@implementation PHThemeModular

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UINavigationBar appearance] setTintColor:PH_ColorWithHexString(@"0x191A1A")];
    
    
    return YES;
}



@end
