//
//  SSAudioLocalDataProvider.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSAudioEngineCommon.h"

@protocol SSAudioDataProvider;
@protocol SSAudioFile;
@protocol SSAudioDataProviderDelegate;

@interface SSAudioLocalDataProvider : NSObject<SSAudioDataProvider>
@property (nonatomic, assign) ssfile_size_t fileSize;
@property (nonatomic, strong) id<SSAudioFile> audioFile;
@property (nonatomic, strong) id<SSAudioDataProviderDelegate> delegaete;
+ (id<SSAudioDataProvider>)dataProviderWithAudioFile:(id<SSAudioFile>)audioFile;
- (void)startReade;
- (void)stopReade;
@end
