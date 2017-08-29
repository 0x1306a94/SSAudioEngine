//
//  SSAudioFrame.m
//  SSAudioToolBox
//
//  Created by king on 2017/8/27.
//  Copyright © 2017年 king. All rights reserved.
//

#import "SSAudioFrame.h"

@implementation SSAudioFrame
- (void)dealloc
{
    @synchronized (self) {
        if (self->data != NULL) {
            free(self->data);
            self->data = NULL;
            NSLog(@"[SSAudioFrame free samples]");
        }
        NSLog(@"[SSAudioFrame dealloc]");
    }
}


@end
