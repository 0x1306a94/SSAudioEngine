//
//  SSAudioFileStreamDecoder.m
//  SSAudioEngineSample
//
//  Created by king on 2017/9/25.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioFileStreamDecoder.h"
#import "SSAudioEngineUtility.h"
#import "SSAudioFrame.h"

static void SSAudioFileStreamPropertyListener(void* inClientData,
                                              AudioFileStreamID inAudioFileStream,
                                              AudioFileStreamPropertyID inPropertyID,
                                              UInt32* ioFlags);

static void SSAudioFileStreamPacketsCallback(void* inClientData,
                                             UInt32 inNumberBytes,
                                             UInt32 inNumberPackets,
                                             const void* inInputData,
                                             AudioStreamPacketDescription *inPacketDescriptions);

@implementation SSAudioFileStreamDecoder
{
    AudioFileStreamID audioFileStreamID;
    
}
- (instancetype)initWithDataProvider:(id<SSAudioDataProvider>)dataProvider {
    if (!dataProvider) {
        return nil;
    }
    
    if (self == [super init]) {
        
        _dataProvider = dataProvider;
    }
    return self;
}
- (void)startDecode {
    
    if (audioFileStreamID == NULL) {
        OSStatus status = AudioFileStreamOpen((__bridge void *)(self),
                            SSAudioFileStreamPropertyListener,
                            SSAudioFileStreamPacketsCallback,
                            kAudioFileWAVEType,
                            &audioFileStreamID);
        NSLog(@"%d", status);
    }
    [NSThread detachNewThreadSelector:@selector(start) toTarget:self withObject:nil];
}

- (void)stopDecode {
    
}

- (void)start {
    
    [NSThread currentThread].name = @"SSAudioFileStreamDecoder";
    while (1) {
        
        NSData *data = nil;
        int ret = [self.dataProvider readDataWithLength:1024 bytes:&data];
//        NSLog(@"SSAudioFileStreamDecoder 需要读取: %d 本次读取: %ld 总共读取:%llu 文件大小: %llu",1024, data.length, self.dataProvider.loc, self.dataProvider.fileSize) ;
        if (ret == -1) {
            NSLog(@"文件读取完毕");
            break;
        }
        if (data && data.length > 0) {
            OSStatus status = AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], 0);
            NSLog(@"%d", status);
            switch (status) {
                    case kAudioFileStreamError_UnsupportedFileType:
                {
                    NSLog(@"kAudioFileStreamError_UnsupportedFileType");
                }
                    break;
                    case kAudioFileStreamError_UnsupportedDataFormat:
                {
                    NSLog(@"kAudioFileStreamError_UnsupportedDataFormat");
                }
                    break;
                    case kAudioFileStreamError_UnsupportedProperty:
                {
                    NSLog(@"kAudioFileStreamError_UnsupportedProperty");
                }
                    break;
                    case kAudioFileStreamError_BadPropertySize:
                {
                    NSLog(@"kAudioFileStreamError_BadPropertySize");
                }
                    break;
                    case kAudioFileStreamError_NotOptimized:
                {
                    NSLog(@"kAudioFileStreamError_NotOptimized");
                }
                    break;
                    case kAudioFileStreamError_InvalidPacketOffset:
                {
                    NSLog(@"kAudioFileStreamError_InvalidPacketOffset");
                }
                    break;
                    case kAudioFileStreamError_InvalidFile:
                {
                    NSLog(@"kAudioFileStreamError_InvalidFile");
                }
                    break;
                    case kAudioFileStreamError_ValueUnknown:
                {
                    NSLog(@"kAudioFileStreamError_ValueUnknown");
                }
                    break;
                    case kAudioFileStreamError_DataUnavailable:
                {
                    NSLog(@"kAudioFileStreamError_DataUnavailable");
                }
                    break;
                    case kAudioFileStreamError_IllegalOperation:
                {
                    NSLog(@"kAudioFileStreamError_IllegalOperation");
                }
                    break;
                    case kAudioFileStreamError_UnspecifiedError:
                {
                    NSLog(@"kAudioFileStreamError_UnspecifiedError");
                }
                    break;
                    case kAudioFileStreamError_DiscontinuityCantRecover:
                {
                    NSLog(@"kAudioFileStreamError_DiscontinuityCantRecover");
                }
                    break;
                default:
                    break;
            }
            if (status != noErr) {
                break;
            }
        }
    }
}
- (void)_AudioFileStreamPropertyListener:(AudioFileStreamID)inAudioFileStream
                              propertyID:(AudioFileStreamPropertyID)inPropertyID
                                 ioFlags:(UInt32 *)flags {
    
    /*
     kAudioFileStreamProperty_ReadyToProducePackets //准备开始
     kAudioFileStreamProperty_FileFormat
     kAudioFileStreamProperty_DataFormat
     kAudioFileStreamProperty_FormatList
     kAudioFileStreamProperty_MagicCookieData
     kAudioFileStreamProperty_AudioDataByteCount
     kAudioFileStreamProperty_AudioDataPacketCount
     kAudioFileStreamProperty_MaximumPacketSize
     kAudioFileStreamProperty_DataOffset //头部偏移量
     kAudioFileStreamProperty_ChannelLayout
     kAudioFileStreamProperty_PacketToFrame
     kAudioFileStreamProperty_FrameToPacket
     kAudioFileStreamProperty_PacketToByte
     kAudioFileStreamProperty_ByteToPacket
     kAudioFileStreamProperty_PacketTableInfo
     kAudioFileStreamProperty_PacketSizeUpperBound
     kAudioFileStreamProperty_AverageBytesPerPacket
     kAudioFileStreamProperty_BitRate
     kAudioFileStreamProperty_InfoDictionary
     */
    
    UInt32 pdSize = 0 ;
    
    switch (inPropertyID) {
        case kAudioFileStreamProperty_AudioDataByteCount:
        {
            pdSize = sizeof(UInt64) ;
            AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &pdSize, &_totalSize) ;
            NSLog(@"总共的数据大小:%lld",_totalSize);
            
            break;
        }
        case kAudioFileStreamProperty_DataOffset :
        {
            pdSize = sizeof(SInt64) ;
            AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &pdSize, &_headerDataOffset) ;
            NSLog(@"头部偏移量大小:%lld",_headerDataOffset);
            break ;
        }
        case kAudioFileStreamProperty_DataFormat :
        {
            pdSize = sizeof(AudioStreamBasicDescription) ;
            AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &pdSize, &_streamBasicDescription) ;
            
            NSLog(@"mSampleRate: %f", _streamBasicDescription.mSampleRate);
            NSLog(@"mFormatID: %u", _streamBasicDescription.mFormatID);
            NSLog(@"mFormatFlags: %u", _streamBasicDescription.mFormatFlags);
            NSLog(@"mBytesPerPacket: %u", _streamBasicDescription.mBytesPerPacket);
            NSLog(@"mFramesPerPacket: %u", _streamBasicDescription.mFramesPerPacket);
            NSLog(@"mBytesPerFrame: %u", _streamBasicDescription.mBytesPerFrame);
            NSLog(@"mChannelsPerFrame: %u", _streamBasicDescription.mChannelsPerFrame);
            NSLog(@"mBitsPerChannel: %u", _streamBasicDescription.mBitsPerChannel);
            NSLog(@"mReserved: %u", _streamBasicDescription.mReserved);
            NSLog(@"获取音频配置描述");
            break ;
        }
        case kAudioFileStreamProperty_AudioDataPacketCount :
        {
            pdSize = sizeof(UInt64) ;
            AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &pdSize, &_packetCount) ;
            NSLog(@"总共包数量:%lld",_packetCount);
            break ;
        }
        case kAudioFileStreamProperty_BitRate:
        {
            pdSize = sizeof(UInt32) ;
            AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &pdSize, &_bit_rate) ;
            NSLog(@"比特率:%lld",_bit_rate);
            break ;
        }
        case kAudioFileStreamProperty_ReadyToProducePackets:
        {
            if (_bit_rate > 0) {
                _duration = (_totalSize - _headerDataOffset) / (_bit_rate / 8) ;
                NSLog(@"时长:%f",self.duration) ;
            }
            [self.delegate audioDecoderDidDecodeHeaderComplete:self];
            break ;
        }
        default:
            break;
    }
}

- (void)_AudioFileStreamPacketsCallback:(UInt32)inNumberBytes
                          numberPackets:(UInt32)inNumberPackets
                              inputData:(const void *)inInputData
                   inPacketDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions {
    
    @autoreleasepool {
        if (inPacketDescriptions == NULL) {
            return;
        }
        
        for (int i = 0; i < inNumberPackets; i++) {
            @autoreleasepool {
                SSAudioFrame *audioFrame = [[SSAudioFrame alloc] init];
                SInt64 packetStart = inPacketDescriptions[i].mStartOffset;
                UInt32 packetSize = inPacketDescriptions[i].mDataByteSize;
                audioFrame->data = malloc(packetSize);
                audioFrame->length = packetSize;
                audioFrame->asbd = inPacketDescriptions[i];
                memcpy(audioFrame->data, inInputData + packetStart, packetSize);
                if (self.delegate) {
                    [self.delegate audioDecoder:self didDecodeFrame:audioFrame];
                }
            }
        }
    }
}
@end

static void SSAudioFileStreamPropertyListener(void* inClientData,
                                             AudioFileStreamID inAudioFileStream,
                                             AudioFileStreamPropertyID inPropertyID,
                                             UInt32* ioFlags) {
    
    SSAudioFileStreamDecoder *self = (__bridge SSAudioFileStreamDecoder *)inClientData;
                                      
    [self _AudioFileStreamPropertyListener:inAudioFileStream propertyID:inPropertyID ioFlags:ioFlags];
}

static void SSAudioFileStreamPacketsCallback(void* inClientData,
                                            UInt32 inNumberBytes,
                                            UInt32 inNumberPackets,
                                            const void* inInputData,
                                            AudioStreamPacketDescription *inPacketDescriptions) {
    SSAudioFileStreamDecoder *self = (__bridge SSAudioFileStreamDecoder *)inClientData;
    [self _AudioFileStreamPacketsCallback:inNumberBytes numberPackets:inNumberPackets inputData:inInputData inPacketDescriptions:inPacketDescriptions];
}
