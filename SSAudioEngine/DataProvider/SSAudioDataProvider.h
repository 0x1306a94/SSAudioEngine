//
//  SSAudioDataProvider.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSAudioEngineCommon.h"

@protocol SSAudioFile;
@protocol SSAudioDataProviderDelegate;

@protocol SSAudioDataProvider <NSObject>

@required
@property (nonatomic, assign) ssfile_size_t fileSize;
@property (nonatomic, strong) id<SSAudioFile> audioFile;
@property (nonatomic, assign, readonly) ssfile_size_t loc;
@property (nonatomic, weak) id<SSAudioDataProviderDelegate> delegate;

+ (id<SSAudioDataProvider>)dataProviderWithAudioFile:(id<SSAudioFile>)audioFile;
- (void)prepare;
- (int)readDataWithLength:(int)length bytes:(NSData **)dataBuffer;
@end

@protocol SSAudioDataProviderDelegate <NSObject>

@required
- (void)audioDataProviderDidPrepare:(id<SSAudioDataProvider>)audioDataProvider;
@end
