//
//  SSAudioFFmpegDecoder.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/25.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SSAudioEngineCommon.h"
#import "SSAudioDecoder.h"
#import "SSAudioDataProvider.h"

@interface SSAudioFFmpegDecoder : NSObject<SSAudioDecoder>

@property (nonatomic, strong, readonly) NSFileHandle  *handle;
@property (nonatomic, assign, readonly) AudioStreamBasicDescription sdbp;
@property (nonatomic, assign, readonly) int64_t bit_rate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign) ssfile_size_t decodeOffset;
@property (nonatomic, strong) id<SSAudioDecoderDelegate> delegate;
@property (nonatomic, weak, readonly) id<SSAudioDataProvider> dataProvider;
- (instancetype)initWithDataProvider:(id<SSAudioDataProvider>)dataProvider;
- (void)startDecode;
- (void)stopDecode;
@end
