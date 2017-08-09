//
//  DBManager.m
//  App
//
//  Created by 項普華 on 2017/6/17.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHDBManager.h"
#import "PHMacro.h"
#import <sqlite3.h>

@implementation PHDBManager

PH_ShareInstance(PHDBManager);
- (void)ph_init {
}

- (NSString *)dbPath {
    if (!_dbPath) {
        _dbPath = [PH_DOCUMENT_PATH stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.db", PH_BundleIdentifier]];
    }
    return _dbPath;
}

- (FMDatabaseQueue *)databaseQueue {
    if (!_databaseQueue) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[PHDBManager shareInstance].dbPath];
    }
    return _databaseQueue;
}



@end
