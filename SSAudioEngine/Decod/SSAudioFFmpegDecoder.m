//
//  SSAudioFFmpegDecoder.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/25.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioFFmpegDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <Accelerate/Accelerate.h>
#import "SSAudioEngineUtility.h"
#import "SSAudioEngineCommon.h"
#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libswresample/swresample.h"
#import "libswscale/swscale.h"
#import "SSAudioFrame.h"
/**
 // 播放时长计算公式
 t = (f * 8) / b
 
 */
ssfile_size_t offset = 0 ;
ssfile_size_t file_size = 0 ;

static int ffmpeg_read_buffer(void *opaque, uint8_t *buf, int buf_size){

    if(offset >= file_size)
        return -1 ;
    SSAudioFFmpegDecoder *this = (__bridge SSAudioFFmpegDecoder *)opaque ;
    [this.handle seekToFileOffset:offset] ;
    NSData *data = [this.handle readDataOfLength:buf_size + offset > file_size ? (file_size - offset) : buf_size] ;
    [data getBytes:buf range:NSMakeRange(0, data.length)] ;
    offset += data.length ;
    NSLog(@"ffmpeg_read_buffer 需要读取: %d 本次读取: %ld 总共读取:%ld 文件大小: %ld",buf_size, data.length, offset, file_size) ;
    return (int)data.length ;
}

@interface SSAudioFFmpegDecoder ()
@property (nonatomic, assign) BOOL hasHeaderComplete;
@property (nonatomic, assign) BOOL hasStartDecode;
@property (nonatomic, assign) BOOL hasStopDecode;
@end

@implementation SSAudioFFmpegDecoder
{
    AVFormatContext         *_formatCtx;
    AVIOContext             *_ioContext;
    AVStream                *_stream;
    AVCodecParameters       *_codecParameters;
    AVCodecContext          *_codec_context;
    AVCodec                 *_code;
    int                     _audio_stream_id;
    
    AVFrame                 *_temp_frame;
    AVPacket                _packet;
    
    Float64                 _samplingRate;
    UInt32                  _channelCount;
    NSTimeInterval          _timebase;
    SwrContext              *_audio_swr_context;
    void                    *_audio_swr_buffer;
    int                     _audio_swr_buffer_size;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_register_all();
        avformat_network_init();
    });
}
- (instancetype)init {
    if (self == [super init]) {
        self.hasHeaderComplete = NO;
        self.hasStopDecode = NO;
        self.hasStartDecode = NO;
       
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"林俊杰 - 可惜没如果.wav" ofType:nil];
        filePath = [[NSBundle mainBundle] pathForResource:@"t6.aac" ofType:nil];
        filePath = [[NSBundle mainBundle] pathForResource:@"t1.mp3" ofType:nil];
        filePath = [[NSBundle mainBundle] pathForResource:@"有一种爱叫做放手.flac" ofType:nil];
//        filePath = [[NSBundle mainBundle] pathForResource:@"期待爱(feat.金莎).ape" ofType:nil];
        _handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        file_size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileSize] unsignedLongLongValue] ;
    }
    return self;
}
- (void)setupSwsContext
{
    _samplingRate = 44100;
    _channelCount = 2;
    _audio_swr_context = swr_alloc_set_opts(NULL, av_get_default_channel_layout(_channelCount), AV_SAMPLE_FMT_S16, _samplingRate, av_get_default_channel_layout(_codec_context->channels), _codec_context->sample_fmt, _codec_context->sample_rate, 0, NULL);
    
    int result = swr_init(_audio_swr_context);
    NSError * error = SSFFCheckError(result);
    if (error || !_audio_swr_context) {
        if (_audio_swr_context) {
            swr_free(&_audio_swr_context);
        }
    }
}
- (void)startDecode {
    @synchronized (self) {
        if (self.hasStartDecode) {
            return;
        }
        self.hasStopDecode = NO;
        self.hasStartDecode = YES;
        if (self.hasHeaderComplete) {
            [NSThread detachNewThreadSelector:@selector(decode) toTarget:self withObject:nil];
        } else {
            [NSThread detachNewThreadSelector:@selector(startPrepare) toTarget:self withObject:nil];
        }
    }
}
- (void)stopDecode {
    @synchronized (self) {
        self.hasStopDecode = YES;
        self.hasStartDecode = NO;
    }
}
- (void)startPrepare {
    
    _formatCtx = avformat_alloc_context();
    
    unsigned char *audioBuffer = (unsigned char *)av_malloc(ffmpeg_audio_buffer_size);
    _ioContext = avio_alloc_context(audioBuffer,
                                    ffmpeg_audio_buffer_size,
                                    0,
                                    (__bridge void *)self,
                                    ffmpeg_read_buffer,
                                    NULL,
                                    NULL);
    _formatCtx->pb = _ioContext;
    if (avformat_open_input(&_formatCtx, NULL, NULL, NULL)) {
        NSLog(@"无法打开源....");
        return;
    }
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"爱笑的眼睛.ape" ofType:nil];
//    if (avformat_open_input(&_formatCtx, [filePath UTF8String], NULL, NULL)) {
//        NSLog(@"无法打开源....");
//        return;
//    }
    if (avformat_find_stream_info(_formatCtx, NULL) < 0) {
        NSLog(@"查找流失败...");
        return;
    }
    
    _audio_stream_id = -1;
    for (int i = 0; i < _formatCtx->nb_streams; i++) {
        if (_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            _audio_stream_id = i;
            break;
        }
    }
    
    if (_audio_stream_id == -1) {
        NSLog(@"找不到音频流....");
        return;
    }
    
    _stream = _formatCtx->streams[_audio_stream_id];
    _code = avcodec_find_decoder(_stream->codec->codec_id);
    if (_code == NULL) {
        NSLog(@"找不到解码器....");
        return;
    }
    _codec_context = avcodec_alloc_context3(_code);
    if (avcodec_parameters_to_context(_codec_context, _stream->codecpar) < 0) {
        NSLog(@"初始化解码器上下文失败...");
        return;
    }
    if (avcodec_open2(_codec_context, _code, NULL) < 0) {
        NSLog(@"解码器打开失败...");
        return;
    }
    _timebase = SSFFStreamGetTimebase(_stream, 0.000025);
    NSLog(@"duration: %lld", _formatCtx->duration / AV_TIME_BASE);
    NSLog(@"bit_rate: %lld", _codec_context->bit_rate);
    NSLog(@"sample_rate: %d", _codec_context->sample_rate);
    NSLog(@"bits_per_raw_sample: %d", _codec_context->bits_per_raw_sample);
    NSLog(@"channels: %d", _codec_context->channels);
    NSLog(@"code_name: %s", _codec_context->codec->name);
    NSLog(@"extra data size: %d", _codec_context->extradata_size);
    NSLog(@"block_align: %d", _codec_context->block_align);

    if (_codec_context->bit_rate <= 0) {
        if (_formatCtx->duration <= 0) {
            _bit_rate = 900000;
        } else {
            _bit_rate = (file_size * 8) / (_formatCtx->duration / AV_TIME_BASE);
        }
    } else {
        _bit_rate = _codec_context->bit_rate;
    }
    if (_formatCtx->duration <= 0) {
        _duration = (file_size * 8) / _bit_rate;
    } else {
        _duration = _formatCtx->duration / AV_TIME_BASE;
    }
    self.hasHeaderComplete = YES;
    [self setupSwsContext];
    if (self.delegate) {
        [self.delegate audioDecoderDidDecodeHeaderComplete:self];
    }
    _temp_frame = av_frame_alloc();
    av_init_packet(&_packet);
    [self decode];
}

- (void)decode {
    
    av_packet_unref(&_packet);
    av_frame_unref(_temp_frame);
    while (YES) {
        if (self.hasStopDecode) {
            break;
        }
        int ret = av_read_frame(_formatCtx, &_packet);
        if (ret == 0) {
            if (_packet.stream_index == _audio_stream_id) {
                if ([self putPacket:_packet] < 0) {
                    continue;
                }
            }
            av_frame_unref(_temp_frame);
            av_packet_unref(&_packet);
        } else {
            NSLog(@"av_read_frame error: %d", ret);
            break;
        }
    }
}
- (int)putPacket:(AVPacket)packet {
    
    if (packet.data == NULL) return 0;
    int result = avcodec_send_packet(_codec_context, &packet);
    if (result < 0 && result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
        return -1;
    }
    
    while (result >= 0) {
        result = avcodec_receive_frame(_codec_context, _temp_frame);
        if (result < 0) {
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                return -1;
            }
            break;
        }
        @autoreleasepool
        {
            SSAudioFrame * frame = [self decodeWithPacketSize:packet.size];
            if (frame) {
                if (self.delegate) {
                    [self.delegate audioDecoder:self didDecodeFrame:frame];
                }
            }
        }
    }
    return 0;
}
- (SSAudioFrame *)decodeWithPacketSize:(int)packetSize {
    if (!_temp_frame->data[0]) {
        return nil;
    }
    int numberOfFrames;
    void * audioDataBuffer;
    
    if (_audio_swr_context) {
        // 重采样
        const int ratio = MAX(1, _samplingRate / _codec_context->sample_rate) * MAX(1, _channelCount / _codec_context->channels) * 2;
        const int buffer_size = av_samples_get_buffer_size(NULL, _channelCount, _temp_frame->nb_samples * ratio, AV_SAMPLE_FMT_S16, 1);
        
        if (!_audio_swr_buffer || _audio_swr_buffer_size < buffer_size) {
            _audio_swr_buffer_size = buffer_size;
            _audio_swr_buffer = realloc(_audio_swr_buffer, _audio_swr_buffer_size);
        }
        
        Byte * outyput_buffer[2] = {_audio_swr_buffer, 0};
        numberOfFrames = swr_convert(_audio_swr_context, outyput_buffer, _temp_frame->nb_samples * ratio, (const uint8_t **)_temp_frame->data, _temp_frame->nb_samples);
        NSError * error = SSFFCheckError(numberOfFrames);
        if (error) {
            NSLog(@"audio codec error : %@", error);
            return nil;
        }
        audioDataBuffer = _audio_swr_buffer;
    } else {
        if (_codec_context->sample_fmt != AV_SAMPLE_FMT_S16) {
            NSLog(@"audio format error");
            return nil;
        }
        audioDataBuffer = _temp_frame->data[0];
        numberOfFrames = _temp_frame->nb_samples;
    }
    

    const NSUInteger numElements = numberOfFrames * _codec_context->channels;
    NSMutableData *data = [NSMutableData dataWithLength:numElements * sizeof(float)];
    vDSP_vflt16(audioDataBuffer, 1, data.mutableBytes, 1, numElements);
    float scale = 1.0 / (float) INT16_MAX;
    vDSP_vsmul(data.mutableBytes, 1, &scale, data.mutableBytes, 1, numElements);
    
    SSAudioFrame *audioFrame = [[SSAudioFrame alloc] init];
    audioFrame->data = malloc([data length]);
    memcpy(audioFrame->data, [data bytes], [data length]);
    
    audioFrame->length = [data length];
    audioFrame->output_offset = 0;
    AudioStreamPacketDescription packetDescription  ;
    packetDescription.mStartOffset = 0 ;
    packetDescription.mDataByteSize = [data length] ;
    packetDescription.mVariableFramesInPacket = 0 ;
    audioFrame->asbd = packetDescription;
    audioFrame.position = av_frame_get_best_effort_timestamp(_temp_frame) * _timebase;
    audioFrame.duration = av_frame_get_pkt_duration(_temp_frame) * _timebase;

    if (audioFrame.duration == 0) {
        audioFrame.duration = audioFrame->length / (sizeof(float) * _channelCount * _samplingRate);
    }
    return audioFrame;
}
@end
