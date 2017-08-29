//
//  SSAudioLocalDataProvider.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioLocalDataProvider.h"
#import "SSAudioDataProvider.h"
#import "SSAudioFile.h"
#import "SSAudioEngineCommon.h"
#import "SSAudioEngineUtility.h"
#import "NSString+SSURL.h"

@interface SSAudioLocalDataProvider ()
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, assign) ssfile_size_t loc;
@property (nonatomic, assign) ssfile_size_t len;
@property (nonatomic, assign) BOOL stop;
@property (nonatomic, assign) BOOL read;
@end

@implementation SSAudioLocalDataProvider
+ (id<SSAudioDataProvider>)dataProviderWithAudioFile:(id<SSAudioFile>)audioFile {
    SSAudioLocalDataProvider *provider = [[SSAudioLocalDataProvider alloc] init];
    if (provider) {
        provider.audioFile = audioFile;
        NSString *path = [[[audioFile ss_audioURL] absoluteString] URLDecodeString];
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        provider.handle = [NSFileHandle fileHandleForReadingAtPath:path];
        provider.fileSize = ss_fileSize(path);
        provider.loc = 0;
        provider.len = 1024;
        provider.stop = NO;
        provider.read = NO;
    }
    return provider;
}

- (void)startReade {
    @synchronized (self) {
        if (self.read) {
            return;
        }
        [NSThread detachNewThreadSelector:@selector(readFile) toTarget:self withObject:nil];
        self.read = YES;
        self.stop = NO;
    }
}
- (void)stopReade {
    @synchronized (self) {
        self.stop = YES;
        self.read = NO;
        NSLog(@"SSAudioLocalDataProvider 停止读取...");
    }
}

- (void)readFile {
    NSThread *thread = [NSThread currentThread];
    thread.name = @"com.king129.SSAudioDataProvider.thread";
    NSLog(@"thread: %@", thread);
    while (self.fileSize > self.loc && !self.stop) {
        @autoreleasepool {
            NSInteger readLen = 0;
            if (self.fileSize >= self.loc + self.len) {
                readLen = self.len;
            } else {
                readLen = self.fileSize - self.loc;
                if (readLen > self.len) {
                    readLen = self.len;
                }
            }
            [self.handle seekToFileOffset:self.loc];
            NSData *data = [self.handle readDataOfLength:readLen];
            if (data && data.length > 0) {
                NSLog(@"SSAudioLocalDataProvider 读取数据: %ld", data.length);
                self.loc += readLen;
                !self.delegaete ? : [self.delegaete audioDataProviderDelegate:self didReadData:data];
            }
        }
    }
}
@end
