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
        self.ss_audioURL = [NSURL fileURLWithPath:@"/Users/king/Documents/无损音频/有一种爱叫做放手.flac"];
    }
    return self;
}
@end
