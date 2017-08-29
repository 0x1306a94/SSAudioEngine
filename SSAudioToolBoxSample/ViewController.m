//
//  ViewController.m
//  SSAudioToolBoxSample
//
//  Created by king on 2017/8/5.
//  Copyright © 2017年 king. All rights reserved.
//

#import "ViewController.h"
#import "SSAudioDownload.h"
#import "MusicModel.h"
#import "SSAudioStreamer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()
@property (nonatomic, strong) SSAudioStreamer *streamer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.download = [[SSAudioDownload alloc] initWithURL:[NSURL URLWithString:@"http://120.25.76.67/OBD/vae.mp3"]];
//    self.download = [[SSAudioDownload alloc] initWithURL:[NSURL URLWithString:@"http://audio01.th-music.com/0102/M00/00/6B/ChR45Vl8woWAY-XMAXb49KUcmW459.flac"]];
//    [self.download start];
//    [self.download seek:24574196 / 2];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.download stop]; 
//    });
    
//
//    NSString *path = [self.download.cachesDirectory stringByAppendingPathComponent:ss_md5(@"http://120.25.76.67/OBD/vae.mp3")];
//    [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:@{NSFileProtectionKey: NSFileProtectionNone}];
//    self.handle = [NSFileHandle fileHandleForWritingAtPath:path];
//    [self.download configurationDidReceiveResponseHeadersBlock:^(NSDictionary *headers) {
//        NSLog(@"%@", headers);
//    }];
//    
//    [self.download configurationDidReceiveDataBlock:^(NSData *data) {
//        [self.handle writeData:data];
//        [self.handle seekToEndOfFile];
//    }];
//    
//    [self.download configurationProgressBlock:^(double progress) {
//        NSLog(@"%.02f", progress);
//    }];
//    
//    [self.download configurationCompletedBlock:^{
//        NSLog(@"Completed");
//        [self.handle closeFile];
//    }];
    
//    NSDate *date = [NSDate date];
//    SSAudioFileType type = [SSAudioHelper fetchAudioFileTypeWith:[MusicModel new]];
//    NSLog(@"%d", type);
//    NSLog(@"%f",[[NSDate date] timeIntervalSince1970] - [date timeIntervalSince1970]);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AVAudioSession *session = [AVAudioSession sharedInstance] ;
    NSError *error ;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error] ;
    [session setActive:YES error:&error] ;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.download startOffset:1024 * 5000];
    if (!self.streamer) {
        self.streamer = [[SSAudioStreamer alloc] initWithAudioFile:[[MusicModel alloc] init]];
        [self.streamer prepare];
    }
}


@end
