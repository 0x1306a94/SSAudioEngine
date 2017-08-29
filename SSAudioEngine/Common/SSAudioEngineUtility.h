//
//  SSAudioEngineUtility.h
//  SSAudioEngine
//
//  Created by king on 2017/8/6.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "libavformat/avformat.h"

@interface SSAudioEngineUtility : NSObject

@end


FOUNDATION_EXTERN BOOL ss_existsFile(NSString *path);
FOUNDATION_EXTERN int64_t ss_fileSize(NSString *path);
FOUNDATION_EXTERN NSString * ss_md5(NSString *src);
FOUNDATION_EXTERN NSString *ss_cachesDirectory();
FOUNDATION_EXTERN NSString *ss_tmpDirectory();
FOUNDATION_EXTERN NSString *ss_createAudioSavePath(NSString *url);
FOUNDATION_EXTERN NSString *ss_createAudioInfoSavePath(NSString *url);
FOUNDATION_EXTERN BOOL ss_extendedFileAttribute(NSString *filePath, NSString *key, NSString *value);
FOUNDATION_EXTERN NSString *ss_readExtendedFileAttribute(NSString *filePath, NSString *key);

FOUNDATION_EXTERN NSError * SSFFCheckError(int result);
FOUNDATION_EXTERN NSError * SSFFCheckErrorCode(int result, NSUInteger errorCode);
FOUNDATION_EXTERN double SSFFStreamGetTimebase(AVStream * stream, double default_timebase);
FOUNDATION_EXTERN NSDictionary * SSFFFoundationBrigeOfAVDictionary(AVDictionary * avDictionary);
FOUNDATION_EXTERN AVDictionary * SSFFFFmpegBrigeOfNSDictionary(NSDictionary * dictionary);

FOUNDATION_EXTERN AudioStreamBasicDescription SSSignedIntLinearPCMStreamDescription();
FOUNDATION_EXTERN const OSStatus SSAudioConverterCallbackErr_NoData;
