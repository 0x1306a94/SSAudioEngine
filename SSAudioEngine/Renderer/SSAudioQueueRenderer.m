//
//  SSAudioQueueRenderer.m
//  SSAudioEngineSample
//
//  Created by king on 2017/9/23.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioQueueRenderer.h"

#define MSAudioPlayerSampleRate         44100
#define MSAudioPlayerBitsPerChannel     16
#define MSAudioPlayerFramesPerPacket    1
#define MSAudioPlayerChannelsPerFrame   2
#define MSAudioPlayerCacheSize          1024 * 32


static void MSAudioQueueOutputCallback(void * __nullable       inUserData,
                                AudioQueueRef           inAQ,
                                AudioQueueBufferRef     inBuffer)
{
    SSAudioQueueRenderer * SELF = (__bridge SSAudioQueueRenderer *)inUserData ;
    [SELF qudioQueueOutputCallback:inBuffer] ;
}

@interface SSAudioQueueRenderer ()
@property (nonatomic, assign)AudioStreamBasicDescription stresmBasicDescription ;
@end

@implementation SSAudioQueueRenderer
{
    AudioQueueRef _msAudioQueue ;/*音频播放队列*/
    CFMutableArrayRef _msUsableAudioQueueBufferArray ;/*可用的,音频播放队列buffer pool*/
    CFMutableArrayRef _msAllAudioQueueBufferArray ;/*用来保存buffer的引用*/
    NSCondition *_msAudioQueuePlayLock ;/*音频队列锁*/
}

- (void)dealloc
{
    //清理_msUsableAudioQueueBufferArray
    CFArrayRemoveAllValues(_msUsableAudioQueueBufferArray) ;
    CFAllocatorDeallocate(CFAllocatorGetDefault(), _msUsableAudioQueueBufferArray) ;
    CFRelease(_msUsableAudioQueueBufferArray) ;
    
    //清理分配的AudioQueueBufferRef
    for(int i = 0 ; i < CFArrayGetCount(_msAllAudioQueueBufferArray) ; i ++) {
        AudioQueueBufferRef aqb = (AudioQueueBufferRef)CFArrayGetValueAtIndex(_msAllAudioQueueBufferArray, i) ;
        AudioQueueFreeBuffer(_msAudioQueue, aqb) ;
    }
    
    //清理_msAllAudioQueueBufferArray
    CFArrayRemoveAllValues(_msAllAudioQueueBufferArray) ;
    CFAllocatorDeallocate(CFAllocatorGetDefault(), _msAllAudioQueueBufferArray) ;
    CFRelease(_msAllAudioQueueBufferArray) ;
    
    //清理_msAudioQueue
    AudioQueueDispose(_msAudioQueue, YES) ;
    
}

- (instancetype)initWithDatasource:(id<SSAudioQueueRendererDatasource>)datasource {
    if (self == [super init]) {
        _datasource = datasource;
        _stresmBasicDescription = [self defaultStreamBasicDescription];
        _inBufferByteSize = MSAudioPlayerCacheSize;
        _msAudioQueuePlayLock = [[NSCondition alloc] init] ;
        [self createAudioQueue] ;
    }
    return self;
}
- (AudioStreamBasicDescription)defaultStreamBasicDescription {
    
    AudioStreamBasicDescription format ;
    format.mSampleRate = MSAudioPlayerSampleRate ;
    format.mBitsPerChannel = MSAudioPlayerBitsPerChannel ;
    format.mFramesPerPacket = MSAudioPlayerFramesPerPacket;
    format.mChannelsPerFrame = MSAudioPlayerChannelsPerFrame;
    format.mFormatID = kAudioFormatLinearPCM;//778924083 ;
    format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked  ;
    format.mBytesPerFrame = format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mBytesPerPacket = format.mFramesPerPacket * format.mBytesPerFrame  ;
    return format ;
    
}

- (void)createAudioQueue {
    
    /*创建队列*/
    OSStatus status = AudioQueueNewOutput(&_stresmBasicDescription,
                                          MSAudioQueueOutputCallback,
                                          (__bridge void *)self,
                                          NULL/*当前runloop*/,
                                          NULL/*当前runloop mode*/,
                                          0,
                                          &_msAudioQueue) ;
    if(status != noErr) {
        //创建失败了,清除资源
        AudioQueueDispose(_msAudioQueue, YES/*立即销毁*/) ;
        _msAudioQueue = nil ;
        NSLog(@"创建播放队列失败") ;
        return ;
    }
    NSLog(@"创建队列成功") ;
    
    //创建audio queue buffer pool
    _msUsableAudioQueueBufferArray = CFArrayCreateMutable(CFAllocatorGetDefault(), 3, NULL) ;
    _msAllAudioQueueBufferArray = CFArrayCreateMutable(CFAllocatorGetDefault(), 3, NULL) ;
    for(int i = 0 ; i < 3 ; i ++) {
        AudioQueueBufferRef bufferRef = NULL ;
        AudioQueueAllocateBuffer(_msAudioQueue,_inBufferByteSize * 2, &bufferRef) ;
        CFArrayAppendValue(_msUsableAudioQueueBufferArray, bufferRef) ;
        CFArrayAppendValue(_msAllAudioQueueBufferArray, bufferRef) ;
    }
    
    AudioQueueStart(_msAudioQueue, NULL/*立即开始*/);
    NSLog(@"开始播放") ;
    [NSThread detachNewThreadSelector:@selector(startRead) toTarget:self withObject:nil] ;
}

- (void)pause {
    OSStatus status = AudioQueuePause(_msAudioQueue) ;
    NSLog(@"pause status %d", status);
}

- (void)resume {
    
    OSStatus status = AudioQueueStart(_msAudioQueue, NULL) ;
    NSLog(@"resume status %d", status);
}
- (void)startRead {
    while (1) {
        @autoreleasepool {
            
            [_msAudioQueuePlayLock lock] ;
            
            if(CFArrayGetCount(_msUsableAudioQueueBufferArray) == 0) {
                NSLog(@"等待空闲Audio Queue Buffer") ;
                [_msAudioQueuePlayLock wait] ;//等待audio queue buffer pool有可用的AudioQueueBufferRef
            }
            
            AudioQueueBufferRef audioQueueBuffer = (AudioQueueBufferRef)CFArrayGetValueAtIndex(_msUsableAudioQueueBufferArray, 0) ;//
            UInt32 realSize = 0;
            
            void *buffer = malloc(_inBufferByteSize);
            [self.datasource audioQueueRenderer:self buffer:buffer needSize:_inBufferByteSize realSize:&realSize];
            if (audioQueueBuffer->mUserData == NULL) {
                audioQueueBuffer->mUserData = malloc(realSize);
            }
            memcpy(audioQueueBuffer->mAudioData, buffer, realSize);
            free(buffer);
            audioQueueBuffer->mAudioDataByteSize = realSize;
            AudioQueueEnqueueBuffer(_msAudioQueue, audioQueueBuffer, realSize,NULL) ;
            //从可用中移除
            CFArrayRemoveValueAtIndex(_msUsableAudioQueueBufferArray,0) ;
            [_msAudioQueuePlayLock unlock] ;
        }
        
        
    }
    
}

- (void)qudioQueueOutputCallback:(AudioQueueBufferRef)audioQueueRef {
    [_msAudioQueuePlayLock lock] ;
    //已经有可用的AudioQueueBufferRef
    CFArrayAppendValue(_msUsableAudioQueueBufferArray, audioQueueRef) ;
    NSLog(@"------>[%@]:清理:::%ld",[NSThread currentThread],CFArrayGetCount(_msUsableAudioQueueBufferArray)) ;
    [_msAudioQueuePlayLock signal] ;
    [_msAudioQueuePlayLock unlock] ;
}
@end
