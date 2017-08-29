//
//  SSAudioFile.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/7.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SSAudioFile <NSObject>

@required
///===========================
/// @property ss_audioURL 音频地址
///===========================
@property (nonatomic, strong) NSURL *ss_audioURL;

@end

NS_ASSUME_NONNULL_END
