//
//  SSAudioToolBoxCommon.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/25.
//  Copyright © 2017年 king. All rights reserved.
//

#ifndef SSAudioToolBoxCommon_h
#define SSAudioToolBoxCommon_h

#import <Foundation/Foundation.h>

#ifndef _SSFILE_SIZE_T
#define _SSFILE_SIZE_T
typedef	unsigned long long		ssfile_size_t;
#endif /* _SSFILE_SIZE_T */

static NSInteger  const ffmpeg_audio_buffer_size = 1024 * 32;

#endif /* SSAudioToolBoxCommon_h */
