//
//  SSAudioEngineUtility.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/6.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioEngineUtility.h"
#import <sys/stat.h>
#import <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

@implementation SSAudioEngineUtility

@end

BOOL ss_existsFile(NSString *path) {
    if (!(([path hasPrefix:@"/"] || [path hasPrefix:@"file://"]) && path.length > 1)) {
        return NO;
    }
    if ([path hasPrefix:@"file://"]) {
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    }
    /*
     00                              Existence only
     02                              Write permission
     04                              Read permission
     06                              Read and write permission
     */
    int ret = access([path fileSystemRepresentation], 0);
    return (ret != -1);
}

int64_t ss_fileSize(NSString *path) {
    struct stat buf;
    if (ss_existsFile(path) && stat([path fileSystemRepresentation], &buf) == 0) {
        return (int64_t)buf.st_size;
    }
    return 0;
}
NSString * ss_md5(NSString *src) {
    const char *cStr = [src UTF8String];
    unsigned char result[CC_MD2_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr),result );
    NSMutableString *hash =[NSMutableString string];
    for (int i = 0; i < CC_MD2_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash uppercaseString];
}

NSString *ss_cachesDirectory() {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/SSAudioToolBoxCaches"];
    BOOL b = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&b] && b) {
        NSLog(@"缓存文件夹已存在存在");
    } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"创建缓存文件夹");
        ss_cachesDirectory();
    }
    return path;
}

NSString *ss_tmpDirectory() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
}
NSString *ss_createAudioSavePath(NSString *url) {
    return [ss_cachesDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.data",ss_md5(url)]];
}
NSString *ss_createAudioInfoSavePath(NSString *url) {
    return [ss_cachesDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.info",ss_md5(url)]];
}

BOOL ss_extendedFileAttribute(NSString *filePath, NSString *key, NSString *value) {
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    ssize_t writelen = setxattr([filePath fileSystemRepresentation], [key UTF8String], [data bytes], [data length], 0, 0);
    return (writelen == 0);
}
NSString *ss_readExtendedFileAttribute(NSString *filePath, NSString *key) {
    
    ssize_t readlen = 1024;
    do {
        char buffer[readlen];
        bzero(buffer, sizeof(buffer));
        size_t leng = sizeof(buffer);
        readlen = getxattr([filePath fileSystemRepresentation],
                           [key UTF8String],
                           buffer,
                           leng,
                           0,
                           0);
        if (readlen < 0){
            return nil;
        }
        else if (readlen > sizeof(buffer)) {
            continue;
        }else{
            NSData *data = [NSData dataWithBytes:buffer length:readlen];
            NSString* result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return result;
        }
    } while (YES);
    
    return nil;
}
NSError * SSFFCheckError(int result)
{
    return SSFFCheckErrorCode(result, -1);
}

NSError * SSFFCheckErrorCode(int result, NSUInteger errorCode)
{
    if (result < 0) {
        char * error_string_buffer = malloc(256);
        av_strerror(result, error_string_buffer, 256);
        NSString * error_string = [NSString stringWithFormat:@"ffmpeg code : %d, ffmpeg msg : %s", result, error_string_buffer];
        NSError * error = [NSError errorWithDomain:error_string code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}
double SSFFStreamGetTimebase(AVStream * stream, double default_timebase)
{
    double timebase;
    if (stream->time_base.den > 0 && stream->time_base.num > 0) {
        timebase = av_q2d(stream->time_base);
    } else {
        timebase = default_timebase;
    }
    return timebase;
}
NSDictionary * SSFFFoundationBrigeOfAVDictionary(AVDictionary * avDictionary)
{
    if (avDictionary == NULL) return nil;
    
    int count = av_dict_count(avDictionary);
    if (count <= 0) return nil;
    
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(avDictionary, "", entry, AV_DICT_IGNORE_SUFFIX))) {
        @autoreleasepool {
            NSString * key = [NSString stringWithUTF8String:entry->key];
            NSString * value = [NSString stringWithUTF8String:entry->value];
            [dictionary setObject:value forKey:key];
        }
    }
    
    return dictionary;
}

AVDictionary * SSFFFFmpegBrigeOfNSDictionary(NSDictionary * dictionary)
{
    if (dictionary.count <= 0) {
        return NULL;
    }
    
    __block BOOL success = NO;
    __block AVDictionary * dict = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            av_dict_set_int(&dict, [key UTF8String], [obj integerValue], 0);
            success = YES;
        } else if ([obj isKindOfClass:[NSString class]]) {
            av_dict_set(&dict, [key UTF8String], [obj UTF8String], 0);
            success = YES;
        }
    }];
    if (success) {
        return dict;
    }
    return NULL;
}

AudioStreamBasicDescription SSSignedIntLinearPCMStreamDescription()
{
    
    AudioStreamBasicDescription destFormat;
    bzero(&destFormat, sizeof(AudioStreamBasicDescription));
    destFormat.mSampleRate = 44100.0;
    destFormat.mFormatID = kAudioFormatLinearPCM;
    destFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    destFormat.mFramesPerPacket = 1;
    destFormat.mBytesPerPacket = 4;
    destFormat.mBytesPerFrame = 4;
    destFormat.mChannelsPerFrame = 2;
    destFormat.mBitsPerChannel = 16;
    destFormat.mReserved = 0;
    
    return destFormat;
    
}

const OSStatus SSAudioConverterCallbackErr_NoData = 'ssnd';
