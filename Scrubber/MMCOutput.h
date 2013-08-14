//
//  MMCOutput.h
//  Scrubber
//
//  Created by Sean Dougall on 4/22/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SnoizeMIDI/SnoizeMIDI.h>

@class F53Timecode;

@interface MMCOutput : NSObject
{
    SMPortOutputStream *_output;
    IBOutlet NSTextField *_tcLabel;
    dispatch_queue_t _mtcQueue;
    dispatch_semaphore_t _mtcStopped;
    BOOL _running;
    F53Timecode *_startTimecode;
    F53Timecode *_mtcTimecode;
    int _qfIndex;
}

- (IBAction) scrub:(NSSlider *)sender;
- (IBAction) play:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) stopAndRewind:(id)sender;
- (IBAction) restart:(id)sender;

@end
