//
//  PHUploadHelper.h
//  App
//
//  Created by 項普華 on 2017/7/30.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PHMacro.h"

#define UPLOAD_DEFAULT_NAME [NSString stringWithFormat:@"%@_ios_%@_%zd.jpg", PH_BundleIdentifier, PH_UUID, [[NSDate date] timeIntervalSince1970]]

typedef NS_ENUM(NSUInteger, UploadType) {
    UploadTypeAliYun = 100,//阿里云上传
};


@interface PHUploadHelper : NSObject

PH_ShareInstanceHeader(PHUploadHelper);

@property (nonatomic, assign) UploadType uploadType;

/****************阿里云上传参数***********************/
//文件夹 空间名称
@property (nonatomic, strong) NSString *bucket;
//key
@property (nonatomic, strong) NSString *accessKeyId;
//secret
@property (nonatomic, strong) NSString *accessKeySecret;
//域名
@property (nonatomic, strong) NSString *endpoint;
/****************阿里云上传参数***********************/



/**
 上传图片

 @param image 需要上传的图片
 @param success 上传成功的回调
 */
+ (void)uploadImage:(UIImage *)image
            success:(PHValueBlock)success;

/**
 上传图片

 @param image 需要上传的图片
 @param filename 自定义命名
 @param success 上传成功的回调
 */
+ (void)uploadImage:(UIImage *)image
           filename:(NSString *)filename
            success:(PHValueBlock)success;

/**
 上传文件

 @param filePath 上传文件的本地路径
 @param success 上传成功的回调
 */
+ (void)uploadFilePath:(NSString *)filePath
               success:(PHValueBlock)success;

/**
 上传文件

 @param filePath 上传文件的本地路径
 @param filename 自定义服务端的命名
 @param success 成功的回调
 */
+ (void)uploadFilePath:(NSString *)filePath
              filename:(NSString *)filename
               success:(PHValueBlock)success;


/**
 上传文件
 
 @param uploadData 上传文件data
 @param success 上传成功的回调
 */
+ (void)uploadData:(NSData *)uploadData
           success:(PHValueBlock)success;

/**
 上传文件
 
 @param uploadData 上传文件data
 @param filename 自定义服务端的命名
 @param success 成功的回调
 */
+ (void)uploadData:(NSData *)uploadData
          filename:(NSString *)filename
           success:(PHValueBlock)success;

@end
