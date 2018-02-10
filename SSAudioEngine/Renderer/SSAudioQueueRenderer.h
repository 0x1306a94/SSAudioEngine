//
//  SSAudioQueueRenderer.h
//  SSAudioEngineSample
//
//  Created by king on 2017/9/23.
//  Copyright © 2017年 king. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol SSAudioQueueRendererDatasource;

@interface SSAudioQueueRenderer : NSObject
@property (nonatomic, assign)UInt32 inBufferByteSize ;
@property (nonatomic, weak, readonly) id<SSAudioQueueRendererDatasource> datasource;
- (instancetype)initWithDatasource:(id<SSAudioQueueRendererDatasource>)datasource;
- (void)pause ;
- (void)resume ;
- (void)qudioQueueOutputCallback:(AudioQueueBufferRef)audioQueueRef;
@end


@protocol SSAudioQueueRendererDatasource <NSObject>

@required
- (void)audioQueueRenderer:(SSAudioQueueRenderer *)renderer
                    buffer:(void *)buffer
                  needSize:(UInt32)needSize
                  realSize:(UInt32 *)realSize;
@end
