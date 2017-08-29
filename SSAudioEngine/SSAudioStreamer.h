//
//  SSAudioStreamer.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/7.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol SSAudioFile;

@interface SSAudioStreamer : NSObject

- (instancetype)initWithAudioFile:(id<SSAudioFile>)file;

- (void)prepare;
@end
