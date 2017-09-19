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
#import <TargetConditionals.h>

#ifndef _SSFILE_SIZE_T
#define _SSFILE_SIZE_T
typedef	unsigned long long		ssfile_size_t;
#endif /* _SSFILE_SIZE_T */


#define SSPLATFORM_TARGET_OS_MAC        TARGET_OS_OSX
#define SSPLATFORM_TARGET_OS_IPHONE     TARGET_OS_IOS
#define SSPLATFORM_TARGET_OS_TV         TARGET_OS_TV

#define SSPLATFORM_TARGET_OS_MAC_OR_IPHONE      (SSPLATFORM_TARGET_OS_MAC || SSPLATFORM_TARGET_OS_IPHONE)
#define SSPLATFORM_TARGET_OS_MAC_OR_TV          (SSPLATFORM_TARGET_OS_MAC || SSPLATFORM_TARGET_OS_TV)
#define SSPLATFORM_TARGET_OS_IPHONE_OR_TV       (SSPLATFORM_TARGET_OS_IPHONE || SSPLATFORM_TARGET_OS_TV)


#if SSPLATFORM_TARGET_OS_MAC
static NSInteger const ffmpeg_audio_buffer_size = 1024 * 32;
static NSInteger const ffmpeg_decode_pool_min_buffer_size = ffmpeg_audio_buffer_size;
static NSInteger const ffmpeg_decode_pool_max_buffer_size = ffmpeg_audio_buffer_size * 5;
#elif SSPLATFORM_TARGET_OS_IPHONE_OR_TV
static NSInteger  const ffmpeg_audio_buffer_size = 1024;
static NSInteger const ffmpeg_decode_pool_min_buffer_size = ffmpeg_audio_buffer_size;
static NSInteger const ffmpeg_decode_pool_max_buffer_size = ffmpeg_audio_buffer_size * 10;
#endif

#endif /* SSAudioToolBoxCommon_h */
