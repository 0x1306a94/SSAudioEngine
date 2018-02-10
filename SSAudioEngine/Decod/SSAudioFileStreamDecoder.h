//
//  SSAudioFileStreamDecoder.h
//  SSAudioEngineSample
//
//  Created by king on 2017/9/25.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SSAudioEngineCommon.h"
#import "SSAudioDecoder.h"
#import "SSAudioDataProvider.h"

@interface SSAudioFileStreamDecoder : NSObject<SSAudioDecoder>

@property (nonatomic, strong, readonly) NSFileHandle  *handle;
@property (nonatomic, assign, readonly) AudioStreamBasicDescription sdbp;
@property (nonatomic, assign, readonly) int64_t bit_rate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign) ssfile_size_t decodeOffset;


/**头信息偏移量*/
@property (nonatomic, assign,readonly)SInt64 headerDataOffset ;
/**文件数据总大小*/
@property (nonatomic, assign,readonly)UInt64 totalSize ;
/**音频描述文件*/
@property (nonatomic, assign,readonly)AudioStreamBasicDescription streamBasicDescription ;

/**总共包数量*/
@property (nonatomic, assign,readonly)UInt64 packetCount ;
/**时长*/
//@property (nonatomic, assign,readonly)CGFloat duration;


@property (nonatomic, strong) id<SSAudioDecoderDelegate> delegate;
@property (nonatomic, weak, readonly) id<SSAudioDataProvider> dataProvider;
- (instancetype)initWithDataProvider:(id<SSAudioDataProvider>)dataProvider;
- (void)startDecode;
- (void)stopDecode;
@end
