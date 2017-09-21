//
//  SSAudioDecoder.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SSAudioDecoderDelegate;
@protocol SSAudioDataProvider;

@class SSAudioFrame;

@protocol SSAudioDecoder <NSObject>
@required
@property (nonatomic, assign, readonly) AudioStreamBasicDescription sdbp;
@property (nonatomic, assign, readonly) int64_t bit_rate;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, strong) id<SSAudioDecoderDelegate> delegate;
@property (nonatomic, weak, readonly) id<SSAudioDataProvider> dataProvider;

- (instancetype)initWithDataProvider:(id<SSAudioDataProvider>)dataProvider;
- (void)startDecode;
- (void)stopDecode;
@end

@protocol SSAudioDecoderDelegate <NSObject>

@required
- (void)audioDecoder:(id<SSAudioDecoder>)decoder didDecodeFrame:(SSAudioFrame *)frame;
- (void)audioDecoderDidDecodeHeaderComplete:(id<SSAudioDecoder>)decoder;
@end
