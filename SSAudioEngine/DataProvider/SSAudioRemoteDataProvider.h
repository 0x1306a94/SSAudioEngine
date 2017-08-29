//
//  SSAudioRemoteDataProvider.h
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SSAudioDataProvider;
@protocol SSAudioFile;
@protocol SSAudioDataProviderDelegate;

@interface SSAudioRemoteDataProvider : NSObject<SSAudioDataProvider>
@property (nonatomic, strong) id<SSAudioFile> audioFile;
@property (nonatomic, strong) id<SSAudioDataProviderDelegate> delegaete;
@end
