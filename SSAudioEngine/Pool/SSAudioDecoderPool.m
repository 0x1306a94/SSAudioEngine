//
//  SSAudioDecoderPool.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/26.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioDecoderPool.h"
#import "SSAudioFrame.h"

@interface SSAudioDecoderPool ()
@property (nonatomic, strong)NSCondition *minLock ;
@property (nonatomic, strong)NSCondition *maxLock ;
@property (nonatomic, assign)UInt32 totalBufferSize ;//总共读取了多少缓存
@property (nonatomic, strong) NSMutableArray<SSAudioFrame *> *pool;
@property (nonatomic, assign) BOOL hasPlay;
@end

@implementation SSAudioDecoderPool
- (void)dealloc {
    
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.minLock = [[NSCondition alloc] init] ;
        self.maxLock = [[NSCondition alloc] init] ;
        self.pool = [NSMutableArray<SSAudioFrame *> array];
    }
    return self;
}
- (void)pushDecodedData:(SSAudioFrame *)_model {
    
    [self.minLock lock];
    SSAudioFrame  *model = _model;
    [self.pool addObject:model];
    self.bufferSize += model->length;
    self.totalBufferSize += model->length;
    NSLog(@"SSAudioDecoderPool 放入数据:%d,总共的缓存:%d",self.bufferSize,self.totalBufferSize);
    if (self.bufferSize >= self.minBufferSize) {
        [self.minLock signal];
        if (!_hasPlay) {
            if (self.delegaet) {
                [self.delegaet hasEnoughBufferToPlay];
            }
            _hasPlay = YES;
        }
        
    }
    [self.minLock unlock];
    
    [self.maxLock lock] ;
    if(self.bufferSize > self.maxBufferSize) {
        NSLog(@"SSAudioDecoderPool 缓存太大,等待减少...") ;
        [self.maxLock wait] ;
        NSLog(@"SSAudioDecoderPool 缓存过大等待结束...") ;
    }
    [self.maxLock unlock] ;
}
- (SSAudioFrame *)popDecodeData {
    
    [self.maxLock lock];
    [self.maxLock signal];
    [self.maxLock unlock];
    
    [self.minLock lock];
    
    if (self.pool.count == 0 || self.bufferSize < self.minBufferSize) {
        NSLog(@"等待pcm数据解析进入pcm data buffer.");
        if (self.delegaet) {
            [self.delegaet waitingForMoreDecodeBuffer];
        }
        [self.minLock wait];
        if (self.delegaet) {
            [self.delegaet hasEnoughDecodeBuffer];
        }
    }
    SSAudioFrame *data;
    if (self.bufferSize > 0) {
        data = [self.pool firstObject];
        [self.pool removeObjectAtIndex:0];
    }
    self.bufferSize -= data->length;
    NSLog(@"SSAudioDecoderPool 读取数据: %u", (unsigned int)data->length);
    [self.minLock unlock];
    return data;
}
@end
