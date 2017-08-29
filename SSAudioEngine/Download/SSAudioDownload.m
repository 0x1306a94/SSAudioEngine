//
//  SSAudioDownload.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/5.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioDownload.h"
#import <CFNetwork/CFNetwork.h>
#import <pthread.h>
#import <CommonCrypto/CommonDigest.h>
#import "SSAudioEngineUtility.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"


ssfile_size_t const kFileInfoMapSacleValue              = 1024 * 10;
// 文件总大小
static NSString *const kFileResponseContentLengthKey    = @"kFileResponseContentLengthKey";
// 文件真实下载大小
static NSString *const kFileHaveDownloadedCountKey      = @"kFileHaveDownloadedCountKey";
// 是否已经下载了尾数值
static NSString *const kFileDownloadMantissaKey         = @"kFileDownloadMantissaKey";
// 是否已经完整下载
static NSString *const kFileCompleteDownloadKey            = @"kFileCompleteDownloadKey";
/**
 数据回调
 
 @param stream 流
 @param type 类型
 @param clientCallBackInfo info
 */
static void _CFReadStreamClientCallback(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo);


@interface SSAudioDownload ()
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, assign) NSInteger downloadSpeed;
@property (nonatomic, assign) CFAbsoluteTime startedTime;
@property (nonatomic, assign) BOOL failed;

@property (nonatomic, strong) NSFileHandle *audioDataHandle;
@property (nonatomic, strong) NSFileHandle *audioInfoHandle;
@property (nonatomic, strong) NSString *savePath;
@property (nonatomic, strong) NSString *infoPath;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, assign) ssfile_size_t startOffset;
@property (nonatomic, assign) ssfile_size_t endOffset;
@property (nonatomic, assign) ssfile_size_t downloadedCount;

@property (nonatomic, strong) NSMutableData *tmpData;
@property (nonatomic, assign) ssfile_size_t totalDownloadCount;
@property (nonatomic, assign) ssfile_size_t totalCount;

/**
 当次下载数量
 */
@property (nonatomic, assign) ssfile_size_t currentDownloadCount;
/** 尾数值  */
@property (nonatomic, assign) ssfile_size_t mantissaSize;

/**
 是否已经下载了尾数值
 */
@property (nonatomic, assign) BOOL mantissaState;
@end

@implementation SSAudioDownload
{
    CFReadStreamRef     _readStreamRef;
}

+ (NSThread *)downloadThread {
    
    static NSThread *_thread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadThreadEntryPoint:) object:nil];
        [_thread start];
    });
    return _thread;
}
+ (void)downloadThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.king129.SSAudioToolBox.download"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}
- (instancetype)initWithURL:(NSURL *)url {
    NSParameterAssert(url);
    if (!url) { return nil; }
    if (self == [super init]) {
        self.url = url;
        self.timeoutInterval = 30.0;
        self.totalDownloadCount = 0;
        self.mantissaState = NO;
        _completeDownload = NO;
        _startOffset = 0;
        _endOffset = 0;
        _responseContentLength = 0;
    }
    return [self prepare];
}

- (instancetype)prepare {
    
    self.fileManager = [NSFileManager defaultManager];
    
    self.savePath = ss_createAudioSavePath(self.url.absoluteString);
    self.infoPath = ss_createAudioInfoSavePath(self.url.absoluteString);
    
    if (![self.fileManager fileExistsAtPath:self.savePath]) {
        if ([self.fileManager createFileAtPath:self.savePath contents:nil attributes:nil]) {
            NSLog(@"音频文件创建成功");
        } else {
            NSLog(@"音频文件创建失败");
            return nil;
        }
    }
    
    if (![self.fileManager fileExistsAtPath:self.infoPath]) {
        if ([self.fileManager createFileAtPath:self.infoPath contents:nil attributes:nil]) {
            NSLog(@"音频Inof文件创建成功");
        } else {
            NSLog(@"音频Inof文件创建失败");
            return nil;
        }
    }
    
    self.audioDataHandle = [NSFileHandle fileHandleForWritingAtPath:self.savePath];
    self.audioInfoHandle = [NSFileHandle fileHandleForWritingAtPath:self.infoPath];
    
    if (ss_fileSize(self.infoPath) > 0) {
        
        NSString *contentLength = ss_readExtendedFileAttribute(self.savePath, kFileResponseContentLengthKey);
        NSString *havCount = ss_readExtendedFileAttribute(self.savePath, kFileHaveDownloadedCountKey);
        NSString *mantissa = ss_readExtendedFileAttribute(self.savePath, kFileDownloadMantissaKey);
        NSString *complete = ss_readExtendedFileAttribute(self.savePath, kFileCompleteDownloadKey);
        if (complete) {
            _completeDownload = [complete boolValue];
        }
        if (mantissa) {
            self.mantissaState = [mantissa boolValue];
        }
        if (havCount) {
            self.totalDownloadCount = [havCount longLongValue] / kFileInfoMapSacleValue;
            NSLog(@"已经下载: %@", @(self.totalDownloadCount).stringValue);
        }
        if (contentLength) {
            _responseContentLength = [contentLength longLongValue];
            self.totalCount = _responseContentLength / kFileInfoMapSacleValue;
            self.mantissaSize = _responseContentLength - (self.totalCount * kFileInfoMapSacleValue);
            NSLog(@"总大小: %@", @(self.totalCount).stringValue);
            NSLog(@"responseContentLength: %@", @(_responseContentLength).stringValue);
            NSLog(@"%@", [self.fileManager attributesOfItemAtPath:self.savePath error:nil]);
        }
    }
    return self;
}
/**
 查找开始位置

 @param startOffset 开始位置指针
 */
- (void)findStartOffset:(ssfile_size_t *)startOffset {
    ssfile_size_t fileSize = ss_fileSize(self.infoPath);
    if (fileSize <= 0) {
        return;
    }
    NSFileHandle *handler = [NSFileHandle fileHandleForReadingAtPath:self.infoPath];
    ssfile_size_t start = (*startOffset / kFileInfoMapSacleValue);
    ssfile_size_t startVal = 0;
    for (; ;) {
        if (start >= fileSize) {
            break;
        }
        [handler seekToFileOffset:start];
        NSData *data = [handler readDataOfLength:1];
        [data getBytes:&startVal range:NSMakeRange(0, 1)];
        if (startVal == 0) {
            if (start == 0) {
                self.startOffset = 0;
                self.endOffset = 0;
                return;
            } else {
                *startOffset = (start * kFileInfoMapSacleValue);
                [self findEndOffset:&_endOffset withStart:start];
                return;
            }
        }
        start++;
    }
}

/**
 根据开始位置查找结束位置

 @param endOffset 结束位置
 @param startOffset 开始位置
 */
- (void)findEndOffset:(ssfile_size_t *)endOffset withStart:(ssfile_size_t)startOffset {
    *endOffset = 0;
    ssfile_size_t fileSize = ss_fileSize(self.infoPath);
    NSFileHandle *handler = [NSFileHandle fileHandleForReadingAtPath:self.infoPath];
    
    // 查找开始下载位置
    ssfile_size_t start = startOffset;
    NSLog(@"start: %llu", start);
    ssfile_size_t startVal = 0;
    for (; ;) {
        if (start >= fileSize) {
            return;
        }
        [handler seekToFileOffset:start];
        NSData *data = [handler readDataOfLength:1];
        [data getBytes:&startVal range:NSMakeRange(0, 1)];
        if (startVal == 1) {
            *endOffset = start * kFileInfoMapSacleValue;
            NSLog(@"start: %llu", start);
            break;
        }
        start++;
    }
}

- (BOOL)checkIntegrity {
    if (_responseContentLength == 0) {
        return NO;
    }
    if (!_completeDownload) {
        return YES;
    }
    ssfile_size_t fileSize = ss_fileSize(self.infoPath);
    NSFileHandle *handler = [NSFileHandle fileHandleForReadingAtPath:self.infoPath];
    ssfile_size_t start = 0;
    ssfile_size_t startVal = 0;
    BOOL b = YES;
    for (; ;) {
        if (start >= fileSize) {
            b = YES;
            break;
        }
        [handler seekToFileOffset:start];
        NSData *data = [handler readDataOfLength:1];
        [data getBytes:&startVal range:NSMakeRange(0, 1)];
        if (startVal == 0) {
            NSLog(@"start: %llu", start);
            b = NO;
            break;
        }
        start++;
        b = YES;
    }
    return b;
}

/**
 更新info 映射文件信息

 @param start 开始位置
 @param len 长度
 */
- (void)updateInfosWithStart:(ssfile_size_t)start len:(NSInteger)len {
    
    if (len == 0) {
        return;
    }
    
    char *bytes = (char *)malloc(len);
    if (bytes != NULL) {
        memset(bytes, 1, len);
        NSData *data = [NSData dataWithBytes:bytes length:len];
        free(bytes);
        [self.audioInfoHandle seekToFileOffset:start];
        [self.audioInfoHandle writeData:data];
    }
}

- (void)start {
    self.startOffset = 0;
    self.endOffset = 0;
    [self performSelector:@selector(beginDownload:) onThread:[[self class] downloadThread] withObject:@(NO) waitUntilDone:YES];
}

- (void)seek:(ssfile_size_t)offset {
    if (self.responseContentLength > 0 && offset < self.responseContentLength) {
        [self stop];
        self.endOffset = 0;
        if (offset > (self.totalCount * kFileInfoMapSacleValue)) {
            if (self.mantissaState) {
                return;
            }
            // 从尾数值开始下载
            self.startOffset = (self.totalCount * kFileInfoMapSacleValue);
            [self performSelector:@selector(beginDownload:) onThread:[[self class] downloadThread] withObject:@(YES) waitUntilDone:YES];
        } else {
            
            self.startOffset = offset;
            [self performSelector:@selector(beginDownload:) onThread:[[self class] downloadThread] withObject:@(NO) waitUntilDone:YES];
        }

    }
}

- (void)stop {
    [self stopDownload];
}

- (void)beginDownload:(NSNumber *)isSkipFindStartOffset {
    if (_readStreamRef != NULL) {
        // 已经在下载了
        return;
    }
    if ([self checkIntegrity]) {
        NSLog(@"已经下载完成....不需要再下载");
        return;
    }
    if (!isSkipFindStartOffset || ![isSkipFindStartOffset boolValue]) {
        [self findStartOffset:&(_startOffset)];
    }
    [self request];
}
- (void)stopDownload {
    [self performSelector:@selector(_closeResponseStream) onThread:[self.class downloadThread] withObject:nil waitUntilDone:YES];
}
- (void)request {
    if (_readStreamRef != NULL) {
        // 已经在下载了
        return;
    }
    if (_responseContentLength > 0 && self.startOffset >= _responseContentLength) {
        return;
    }
    CFHTTPMessageRef httpMessage = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (__bridge CFStringRef)@"GET", (__bridge CFURLRef)self.url, kCFHTTPVersion1_1);
    
    if (httpMessage == NULL) {
        return;
    }
    
    if (self.startOffset > 0 && self.endOffset > 0) {
        CFHTTPMessageSetHeaderFieldValue(httpMessage, (__bridge CFStringRef)@"Range", (__bridge CFStringRef _Nullable)([NSString stringWithFormat:@"bytes=%lld-%lld", self.startOffset,self.endOffset]));
    } else if (self.startOffset > 0) {
        CFHTTPMessageSetHeaderFieldValue(httpMessage, (__bridge CFStringRef)@"Range", (__bridge CFStringRef _Nullable)([NSString stringWithFormat:@"bytes=%lld-", self.startOffset]));
    }
    
    _readStreamRef = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, httpMessage);
    CFReadStreamSetProperty(_readStreamRef, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    CFReadStreamSetProperty(_readStreamRef, CFSTR("_kCFStreamPropertyReadTimeout"), (__bridge CFNumberRef)[NSNumber numberWithDouble:_timeoutInterval]);
    CFReadStreamSetProperty(_readStreamRef, CFSTR("_kCFStreamPropertyWriteTimeout"), (__bridge CFNumberRef)[NSNumber numberWithDouble:_timeoutInterval]);
    CFRelease(httpMessage);
    
    CFStreamClientContext clientContext = {0, (__bridge void*)self, NULL, NULL, NULL};
    CFReadStreamSetClient(_readStreamRef, kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventHasBytesAvailable, _CFReadStreamClientCallback, &clientContext);
    
    if(CFReadStreamSetProperty(_readStreamRef, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue) == false) {
        return ;
    }
    
    // 复制系统的代理配置
    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
    if (proxySettings != NULL) {
        CFReadStreamSetProperty(_readStreamRef, kCFStreamPropertyHTTPProxy, proxySettings);
        CFRelease(proxySettings);
    }
    
    // 针对HTTPS 处理
    if([self.url.absoluteString hasPrefix:@"https"])
    {
        NSDictionary *sslSettings =
        [NSDictionary dictionaryWithObjectsAndKeys:
         (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
         [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
         [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredRoots,
         [NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
         [NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
         [NSNull null], kCFStreamSSLPeerName,
         nil];
        
        CFReadStreamSetProperty(_readStreamRef, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)sslSettings);
    }
    
    if(CFReadStreamOpen(_readStreamRef) == false) {
        return ;
    }
    self.currentDownloadCount = 0;
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    // 加入到RunLoop 中
    CFReadStreamScheduleWithRunLoop(_readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    _startedTime = CFAbsoluteTimeGetCurrent();
    _downloadSpeed = 0;
}
- (void)_CFStreamEventHasBytesAvailable {
    
    [self readResponseHeaders];
    
    if (!CFReadStreamHasBytesAvailable(_readStreamRef)) return;
    if (!self.tmpData) {
        self.tmpData = [NSMutableData data];
    }
    CFIndex bufferSize = kFileInfoMapSacleValue - self.tmpData.length;
    UInt8 buffer[bufferSize];
    CFIndex bytesRead = CFReadStreamRead(_readStreamRef, buffer, bufferSize);
    if (bytesRead < 0) {// 获取数据失败
        [self eventEndEncountered];
        return;
    }
    NSLog(@"接受到数据: %@", @((NSInteger)bytesRead).stringValue);
    if (bytesRead > 0) {
        @autoreleasepool {
            [self.tmpData appendBytes:buffer length:bytesRead];
            if (self.tmpData.length == kFileInfoMapSacleValue) {
                
                [self.audioDataHandle seekToFileOffset:self.totalDownloadCount * kFileInfoMapSacleValue];
                [self.audioDataHandle writeData:self.tmpData.copy];
                
                [self updateInfosWithStart:((self.startOffset / kFileInfoMapSacleValue) + self.currentDownloadCount) len:1];
                self.totalDownloadCount++;
                self.currentDownloadCount++;
                NSLog(@"downloadCount: %@", @(self.totalDownloadCount).stringValue);
                [self.tmpData resetBytesInRange:NSMakeRange(0, kFileInfoMapSacleValue)];
                self.tmpData = nil;
                self.tmpData = [NSMutableData data];
                
                ss_extendedFileAttribute(self.savePath, kFileHaveDownloadedCountKey, @(self.totalDownloadCount * kFileInfoMapSacleValue).stringValue);
                [self updateProgress];
                
            } else if (self.totalDownloadCount == self.totalCount && bytesRead == self.mantissaSize) {
                // 尾数值下载完
                [self.audioDataHandle seekToFileOffset:self.totalDownloadCount * kFileInfoMapSacleValue];
                [self.audioDataHandle writeData:self.tmpData.copy];
                self.tmpData = nil;
                ss_extendedFileAttribute(self.savePath, kFileHaveDownloadedCountKey, @(self.totalDownloadCount * kFileInfoMapSacleValue + bytesRead).stringValue);
                ss_extendedFileAttribute(self.savePath, kFileDownloadMantissaKey, @(YES).stringValue);
                ss_extendedFileAttribute(self.savePath, kFileCompleteDownloadKey, @(YES).stringValue);
                [self updateInfosWithStart:self.totalCount len:1];
                [self downloadComplete];
                [self.audioDataHandle closeFile];
                self.audioDataHandle = nil;
                [self.audioInfoHandle closeFile];
                self.audioInfoHandle = nil;
            } else if (self.startOffset == (self.totalCount * kFileInfoMapSacleValue) && bytesRead == self.mantissaSize) {
                // 从尾数值开始下载的
                [self.audioDataHandle seekToFileOffset:self.totalDownloadCount * kFileInfoMapSacleValue];
                [self.audioDataHandle writeData:self.tmpData.copy];
                self.tmpData = nil;
                ss_extendedFileAttribute(self.savePath, kFileHaveDownloadedCountKey, @(self.totalDownloadCount * kFileInfoMapSacleValue + bytesRead).stringValue);
                ss_extendedFileAttribute(self.savePath, kFileDownloadMantissaKey, @(YES).stringValue);
                [self updateInfosWithStart:self.totalCount len:1];
            }
            [self updateDownloadSpeed];
        }
    }
}

- (void)_CFStreamEventEndEncountered {
    [self eventEndEncountered];
}

- (void)_CFStreamEventErrorOccurred {
    [self eventErrorOccurred];
}

- (void)readResponseHeaders {
    
    if (_responseHeaders != nil) return;
    CFHTTPMessageRef message = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStreamRef, kCFStreamPropertyHTTPResponseHeader);
    if (message == NULL) return;
    
    if (!CFHTTPMessageIsHeaderComplete(message)) {
        CFRelease(message);
        return;
    }
    
    _responseHeaders = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(message));
    _statusCode = CFHTTPMessageGetResponseStatusCode(message);
    _statusMessage = CFBridgingRelease(CFHTTPMessageCopyResponseStatusLine(message));
    NSString *ContentLength = [_responseHeaders objectForKey:@"Content-Length"];
    if (!ss_readExtendedFileAttribute(self.savePath, kFileResponseContentLengthKey) && _responseContentLength == 0) {
        if (ContentLength == nil) {
            _responseContentLength = 0;
        }
        _responseContentLength = (ssfile_size_t)[ContentLength longLongValue];
        self.totalCount = _responseContentLength / kFileInfoMapSacleValue;
        self.mantissaSize = _responseContentLength - (self.totalCount * kFileInfoMapSacleValue);
        ss_extendedFileAttribute(self.savePath, kFileResponseContentLengthKey, ContentLength);
        [self.audioDataHandle truncateFileAtOffset:_responseContentLength];
        [self.audioInfoHandle truncateFileAtOffset:(_responseContentLength / kFileInfoMapSacleValue) + 1];
    }
    CFRelease(message);
    
}

- (void)eventEndEncountered {
    [self readResponseHeaders];
    _failed = NO;
}

- (void)eventErrorOccurred {
    [self readResponseHeaders];
    _failed = YES;
    [self _closeResponseStream];
    
}

- (void)updateProgress {
    if (_responseContentLength == 0) {
        if (_responseHeaders != nil) {
            _downloadProgress = 1.0;
        }
        else {
            _downloadProgress = 0.0;
        }
    }
    else {
        _downloadProgress = (float)(self.totalDownloadCount * kFileInfoMapSacleValue * 1.0f) / _responseContentLength;
    }
    
    NSLog(@"downloadProgress: %@", @(_downloadProgress).stringValue);
}
- (void)downloadComplete {
    _downloadProgress = 1.0;
}
static NSByteCountFormatter *formatter = nil;
- (void)updateDownloadSpeed {
    _downloadSpeed = (self.totalDownloadCount * kFileInfoMapSacleValue) / (CFAbsoluteTimeGetCurrent() - _startedTime);
    if (!formatter) {
       formatter = [[NSByteCountFormatter alloc] init];
    }
    formatter.countStyle = NSByteCountFormatterCountStyleFile;
    formatter.allowedUnits = NSByteCountFormatterUseKB;
    NSLog(@"downloadSpeed: %@", @(_downloadSpeed).stringValue);
    NSLog(@"formatter downloadSpeed: %@", [formatter stringFromByteCount:_downloadSpeed]);
}

- (void)_closeResponseStream
{
    if (self.tmpData) {
        self.tmpData = nil;
    }
    if (_readStreamRef == NULL || _failed) return;
    CFReadStreamClose(_readStreamRef);
    CFReadStreamUnscheduleFromRunLoop(_readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFReadStreamSetClient(_readStreamRef, kCFStreamEventNone, NULL, NULL);
    CFRelease(_readStreamRef);
    _readStreamRef = NULL;
}
- (void)dealloc
{
    if (_readStreamRef != NULL) {
        [self _closeResponseStream];
    }
    
}
@end

static void _CFReadStreamClientCallback(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
    
    SSAudioDownload *downloder = (__bridge SSAudioDownload *)(clientCallBackInfo);
    @autoreleasepool {
        @synchronized (downloder) {
            switch (type) {
                    // 有数据可拿
                case kCFStreamEventHasBytesAvailable:
                    [downloder _CFStreamEventHasBytesAvailable];
                    break;
                    // 提取数据结束
                case kCFStreamEventEndEncountered:
                    [downloder _CFStreamEventEndEncountered];
                    break;
                    // 请求发生错误
                case kCFStreamEventErrorOccurred:
                    [downloder _CFStreamEventErrorOccurred];
                    break;
                default:
                    break;
            }
        }
    }
}

#pragma clang diagnostic pop
