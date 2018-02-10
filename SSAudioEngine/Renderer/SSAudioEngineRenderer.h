//
//  SSAudioEngineRenderer.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/25.
//  Copyright © 2017年 king. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@class SSAudioEngineRenderer;
@class SSAudioFrame;

@protocol SSAudioEngineRendererDelegate <NSObject>

@required
- (void)audioEngineRendererNeedFrameData:(SSAudioEngineRenderer *)renderer
                              outputData:(float *)outputData
                          numberOfFrames:(UInt32)numberOfFrames
                        numberOfChannels:(UInt32)numberOfChannels;

- (SSAudioFrame *)audioEngineRendererNeedFrameData:(SSAudioEngineRenderer *)renderer;

@end

@interface SSAudioEngineRenderer : NSObject
@property (nonatomic, weak) id<SSAudioEngineRendererDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL playing;
@property (nonatomic, assign, readonly) BOOL useAudioFileStream;
- (instancetype)initWithUseAudioFileStream:(BOOL)flag;
- (BOOL)cretaeAudioConverterWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription;
- (void)start;
- (void)pause;
@end
