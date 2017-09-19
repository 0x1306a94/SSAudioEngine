//
//  ViewController.m
//  SSAudioEngineOSXSample
//
//  Created by king on 2017/9/19.
//  Copyright © 2017年 king. All rights reserved.
//

#import "ViewController.h"
#import <SSAudioEngineOSX/SSAudioStreamer.h>
#import "MusicModel.h"

@interface ViewController ()
@property (nonatomic, strong) SSAudioStreamer *streamer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!self.streamer) {
            self.streamer = [[SSAudioStreamer alloc] initWithAudioFile:[[MusicModel alloc] init]];
            [self.streamer prepare];
        }
    });
}

@end
