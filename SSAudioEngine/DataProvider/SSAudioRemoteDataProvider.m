//
//  SSAudioRemoteDataProvider.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioRemoteDataProvider.h"
#import "SSAudioDataProvider.h"
#import "SSAudioFile.h"
#import "SSAudioDownload.h"
#import <pthread.h>

@interface SSAudioRemoteDataProvider ()<SSAudioDownloadDelegate>
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, strong) SSAudioDownload *download;
@property (nonatomic, assign) ssfile_size_t loc;
@property (nonatomic, assign) BOOL stop;
@property (nonatomic, assign) BOOL read;
@property (nonatomic, assign) BOOL isPrepare;
@property (nonatomic, assign) ssfile_size_t minSize;
@end


@implementation SSAudioRemoteDataProvider
{
    pthread_mutex_t _mutex;
    pthread_cond_t _cond;
}
+ (id<SSAudioDataProvider>)dataProviderWithAudioFile:(id<SSAudioFile>)audioFile {
    SSAudioRemoteDataProvider *provider = [[SSAudioRemoteDataProvider alloc] init];
    if (provider) {
        provider.audioFile = audioFile;
        provider.loc = 0;
        provider.stop = NO;
        provider.read = NO;
        provider.isPrepare = NO;
        provider.minSize = decode_pool_min_buffer_size;
    }
    return provider;
}
- (void)prepare {
    
    if (self.download) {
        return;
    }
    [self _mutexInit];
    self.download = [[SSAudioDownload alloc] initWithURL:self.audioFile.ss_audioURL delegate:self];
    self.handle = [NSFileHandle fileHandleForReadingAtPath:self.download.savePath];
    [self.download start];
}
- (void)_mutexInit{
    pthread_mutex_init(&_mutex, NULL);
    pthread_cond_init(&_cond, NULL);
}

- (void)waitNetData{
    
    NSLog(@"waitNetData");
    pthread_mutex_lock(&_mutex);
    pthread_cond_wait(&_cond, &_mutex);
    pthread_mutex_unlock(&_mutex);
}

- (void)signalEnughtData{
    
    NSLog(@"数据足了");
    pthread_mutex_lock(&_mutex);
    pthread_cond_signal(&_cond);
    pthread_mutex_unlock(&_mutex);
}

- (void)mutexDestory{
    
    pthread_mutex_destroy(&_mutex);
    pthread_cond_destroy(&_cond);
}

- (int)readDataWithLength:(int)length bytes:(NSData *__autoreleasing *)dataBuffer {
    
    if (self.loc >= self.fileSize) {
        return -1;
    }
    int realLen = 0;
    if (self.loc + length > self.fileSize) {
        realLen = self.fileSize - self.loc;
    } else {
        realLen = length;
    }
    [self.handle seekToFileOffset:self.loc];
    
    NSData *data = [self.handle readDataOfLength:realLen];
    if (!data || [data length] == 0) {
        [self waitNetData];
        return 0;
    }
    *dataBuffer = data;
    self.loc += realLen;
    self.minSize -= realLen;
    return realLen;
}
#pragma mark - SSAudioDownloadDelegate
- (void)audioDownload:(SSAudioDownload *)audioDownload didFetchFileSize:(ssfile_size_t)fileSize {
    self.fileSize = fileSize;
}
- (void)audioDownload:(SSAudioDownload *)audioDownload didFetchResponseHeaders:(NSDictionary *)responseHeaders {
    
}
- (void)audioDownload:(SSAudioDownload *)audioDownload didReceiveData:(NSData *)data {
    
    @synchronized(self) {
        if (audioDownload.totalDownloadCount * 1024 >= decode_pool_min_buffer_size) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(audioDataProviderDidPrepare:)] && !self.isPrepare) {
                [self.delegate audioDataProviderDidPrepare:self];
                self.isPrepare = YES;
            }
        }
        [self signalEnughtData];
    }
}
- (void)audioDownload:(SSAudioDownload *)audioDownload didUpdateProgress:(float)progress {
    
}
- (void)audioDownload:(SSAudioDownload *)audioDownload didUpdateDownloadSpeed:(NSInteger)downloadSpeed {
    
}
- (void)audioDownloadDidCompleted:(SSAudioDownload *)audioDownload {
    NSLog(@"下载完成");
    @synchronized(self) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(audioDataProviderDidPrepare:)] && !self.isPrepare) {
            [self.delegate audioDataProviderDidPrepare:self];
            self.isPrepare = YES;
        }
    }
}
- (void)dealloc {
    [self mutexDestory];
}
@end
