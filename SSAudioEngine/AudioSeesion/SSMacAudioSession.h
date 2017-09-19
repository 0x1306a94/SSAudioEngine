//
//  SSMacAudioSession.h
//  SSAudioEngineSample
//
//  Created by king on 2017/9/19.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SSMacAudioDevice : NSObject

@property (nonatomic, assign) AudioDeviceID deviceID;
@property (nonatomic, copy) NSString * manufacturer;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) NSInteger inputChannelCount;
@property (nonatomic, assign) NSInteger outputChannelCount;
@property (nonatomic, copy) NSString * UID;

@end

@interface SSMacAudioSession : NSObject
+ (instancetype)sharedInstance;

- (NSArray <SSMacAudioDevice *> *)devices;
- (SSMacAudioDevice *)currentDevice;

- (double)sampleRate;
- (NSInteger)outputNumberOfChannels;
@end
