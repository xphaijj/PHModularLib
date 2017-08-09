//
//  PHUploadHelper.m
//  App
//
//  Created by 項普華 on 2017/7/30.
//  Copyright © 2017年 項普華. All rights reserved.
//

#import "PHUploadHelper.h"
#import <AliyunOSSiOS.h>
#import <AliyunOSSiOS/OSSService.h>

@implementation PHUploadHelper

PH_ShareInstance(PHUploadHelper);

- (void)ph_init {
}

/**
 上传图片
 
 @param image 需要上传的图片
 @param success 上传成功的回调
 */
+ (void)uploadImage:(UIImage *)image
            success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:UIImageJPEGRepresentation(image, 0.98) filename:UPLOAD_DEFAULT_NAME success:success];
}

/**
 上传图片
 
 @param image 需要上传的图片
 @param filename 自定义命名
 @param success 上传成功的回调
 */
+ (void)uploadImage:(UIImage *)image
           filename:(NSString *)filename
            success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:UIImageJPEGRepresentation(image, 0.98) filename:filename success:success];
}

/**
 上传文件
 
 @param filePath 上传文件的本地路径
 @param success 上传成功的回调
 */
+ (void)uploadFilePath:(NSString *)filePath
               success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:[NSData dataWithContentsOfFile:filePath] filename:UPLOAD_DEFAULT_NAME success:success];
}

/**
 上传文件
 
 @param filePath 上传文件的本地路径
 @param filename 自定义服务端的命名
 @param success 成功的回调
 */
+ (void)uploadFilePath:(NSString *)filePath
              filename:(NSString *)filename
               success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:[NSData dataWithContentsOfFile:filePath] filename:filename success:success];
}

/**
 上传文件
 
 @param uploadData 上传文件data
 @param success 上传成功的回调
 */
+ (void)uploadData:(NSData *)uploadData
           success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:uploadData filename:UPLOAD_DEFAULT_NAME success:success];
}

/**
 上传文件
 
 @param uploadData 上传文件data
 @param filename 自定义服务端的命名
 @param success 成功的回调
 */
+ (void)uploadData:(NSData *)uploadData
          filename:(NSString *)filename
           success:(PHValueBlock)success {
    [[PHUploadHelper shareInstance] uploadData:uploadData filename:filename success:success];
}


/**
 上传文件
 
 @param uploadData 上传文件data
 @param filename 自定义服务端的命名
 @param success 成功的回调
 */
- (void)uploadData:(NSData *)uploadData
          filename:(NSString *)filename
           success:(PHValueBlock)success {
    switch (self.uploadType) {
        case UploadTypeAliYun: [self aliyunUploadData:uploadData filename:filename success:success];  break;
        default: PHLogError(@"未兼容的上传方式"); break;
    }
}

- (void)aliyunUploadData:(NSData *)uploadData
                filename:(NSString *)filename
                 success:(PHValueBlock)success {
    // 明文设置secret的方式建议只在测试时使用，更多鉴权模式请参考后面的访问控制章节
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:self.accessKeyId secretKey:self.accessKeySecret];
    
    OSSClientConfiguration *conf = [OSSClientConfiguration new];
    conf.maxRetryCount = 3; // 网络请求遇到异常失败后的重试次数
    conf.timeoutIntervalForRequest = 30; // 网络请求的超时时间
    conf.timeoutIntervalForResource = 24 * 60 * 60; // 允许资源传输的最长时间
    
    OSSClient *client = [[OSSClient alloc] initWithEndpoint:self.endpoint credentialProvider:credential clientConfiguration:conf];
    
    
    OSSPutObjectRequest *put = [OSSPutObjectRequest new];
    put.bucketName = self.bucket;
    put.objectKey = filename;
    put.uploadingData = uploadData;
    
    // 可选字段，可不设置
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        // 当前上传段长度、当前已经上传总长度、一共需要上传的总长度
        PHLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    __block NSString *uploadPath = [NSString stringWithFormat:@"%@/%@/%@", self.endpoint, self.bucket, filename];
    OSSTask *putTask = [client putObject:put];
    [putTask continueWithBlock:^id(OSSTask *task) {
        if (task.error) {
            OSSLogError(@"%@", task.error);
        } else {
//            OSSPutObjectResult *result = task.result;
            if (success) {
                success(uploadPath);
            }
        }
        return nil;
    }];
}




@end
