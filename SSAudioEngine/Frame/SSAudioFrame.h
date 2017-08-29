//
//  SSAudioFrame.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/27.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SSAudioFrame : NSObject
{
@public
    void *data;
    int length;
    int output_offset;
    AudioStreamPacketDescription asbd;
}

@property (nonatomic, assign) NSTimeInterval position;
@property (nonatomic, assign) NSTimeInterval duration;
@end
