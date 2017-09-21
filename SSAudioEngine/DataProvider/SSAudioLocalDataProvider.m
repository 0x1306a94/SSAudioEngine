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
        provider.fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil][NSFileSize] unsignedLongLongValue];
        provider.loc = 0;
        provider.stop = NO;
        provider.read = NO;
    }
    return provider;
}
- (void)prepare {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioDataProviderDidPrepare:)]) {
        [self.delegate audioDataProviderDidPrepare:self];
    }
}
- (int)readDataWithLength:(int)length bytes:(NSData **)dataBuffer {
    
    if (self.loc >= self.fileSize) {
        NSLog(@"文件读取完毕");
        return -1;
    }
    // 计算可读数据长度
    int realLen = 0;
    if ((self.loc + length) > self.fileSize) {
        realLen = self.fileSize - self.loc;
    } else {
        realLen = length;
    }
    
    [self.handle seekToFileOffset:self.loc];
    NSData *data = [self.handle readDataOfLength:realLen];
    if (!data || [data length] == 0) {
        return 0;
    }
    *dataBuffer = data;
    self.loc += realLen;
    return realLen;
}
@end
