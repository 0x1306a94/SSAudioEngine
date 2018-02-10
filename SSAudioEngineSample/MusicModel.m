//
//  MusicModel.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/7.
//  Copyright © 2017年 king. All rights reserved.
//

#import "MusicModel.h"

@implementation MusicModel
- (instancetype)init {
    if (self == [super init]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"林俊杰-可惜没如果.wav" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"t6.aac" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"爱笑的眼睛.ogg" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"爱笑的眼睛.m4a" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"爱笑的眼睛.ape" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"有一种爱叫做放手.flac" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"林俊杰-爱不会绝迹.aac" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"t1.mp3" ofType:nil];
        self.ss_audioURL = [NSURL fileURLWithPath:filePath];
        self.ss_audioURL = [NSURL URLWithString:@"http://120.25.76.67/OBD/vae.mp3"];
    }
    return self;
}
@end
