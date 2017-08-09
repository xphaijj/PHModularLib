//
//  DBManager.h
//  App
//
//  Created by 項普華 on 2017/6/17.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHBaseManager.h"
#import <FMDB/FMDB.h>
#import "PHMacro.h"
#import <objc/message.h>

@interface PHDBManager : PHBaseManager

PH_ShareInstanceHeader(PHDBManager);

/**
 数据库路径
 */
@property (nonatomic, strong) NSString *dbPath;

/**
 数据库队列
 */
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end
