//
//  SSAudioDownload.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/5.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSAudioEngineCommon.h"

// 真实文件与info文件映射缩放大小
FOUNDATION_EXTERN ssfile_size_t const kFileInfoMapSacleValue;

@class SSAudioDownload;

typedef void(^SSAudioDownloadDidReceiveResponseHeaders)(NSDictionary *headers);
typedef void(^SSAudioDownloadDidReceiveData)(NSData *data);
typedef void(^SSAudioDownloadProgress)(double progress);
typedef void(^SSAudioDownloadDidCompleted)();

@interface SSAudioDownload : NSObject
/** 超时时间 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/** 返回的http请求头 */
@property (nonatomic, strong, readonly) NSDictionary *responseHeaders;
/** 文件大小 */
@property (nonatomic, assign, readonly) ssfile_size_t responseContentLength;
/** http状态码 */
@property (nonatomic, assign, readonly) NSInteger statusCode;
/** http状态信息 */
@property (nonatomic, strong, readonly) NSString *statusMessage;
/** 下载速度 */
@property (nonatomic, assign, readonly) NSInteger downloadSpeed;
/** 下载进度 */
@property (nonatomic, assign, readonly) float downloadProgress;
/** 下载是否失败 */
@property (nonatomic, readonly, getter=isFailed) BOOL failed;
/** 是否已经完整下载 */
@property (nonatomic, assign, readonly) BOOL completeDownload;
/** 缓存文件地址 */
@property (nonatomic, strong, readonly) NSString *savePath;
- (instancetype)initWithURL:(NSURL *)url;
- (void)start;
- (void)seek:(ssfile_size_t)offset;
- (void)stop;
@end
