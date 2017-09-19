//
//  ViewController.m
//  SSAudioEngineSample
//
//  Created by king on 2017/9/19.
//  Copyright © 2017年 king. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <SSAudioEngineiOS/SSAudioStreamer.h>
#import "MusicModel.h"
@interface ViewController ()
@property (nonatomic, strong) SSAudioStreamer *streamer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AVAudioSession *session = [AVAudioSession sharedInstance] ;
    NSError *error ;
    [session setCategory:AVAudioSessionCategoryPlayback error:&error] ;
    [session setActive:YES error:&error] ;
    
}

- (IBAction)play:(UIButton *)sender {
    if (!self.streamer) {
        self.streamer = [[SSAudioStreamer alloc] initWithAudioFile:[[MusicModel alloc] init]];
        [self.streamer prepare];
    }
}


@end
