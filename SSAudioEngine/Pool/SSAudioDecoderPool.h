//
//  SSAudioDecoderPool.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SSAudioFrame;

@protocol SSAudioDecoderPoolDelegate <NSObject>

/**第一次有足够的解码缓存可以开始启动播放队列了*/
- (void)hasEnoughBufferToPlay;
/**解码缓存区数据不够,等待更多多数据进入*/
- (void)waitingForMoreDecodeBuffer;
/**解码缓存区数据已经达到最小缓存大小*/
- (void)hasEnoughDecodeBuffer;

@end

@interface SSAudioDecoderPool : NSObject
/**最小播放缓存大小*/
@property (nonatomic, assign)UInt32 minBufferSize ;
/**最大播放缓存大小*/
@property (nonatomic, assign)UInt32 maxBufferSize ;
/**当前缓存大小*/
@property (nonatomic, assign)UInt32 bufferSize ;
@property (nonatomic, weak) id<SSAudioDecoderPoolDelegate> delegaet;
/**把解码后的音频数据放入缓存除队列*/
- (void)pushDecodedData:(SSAudioFrame *)model;
- (SSAudioFrame *)popDecodeData;
@end
