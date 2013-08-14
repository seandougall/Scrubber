//
//  F53Timecode-OSCAdditions.m
//
//  Created by Sean Dougall on 2/16/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

/*
 
 Encodes timecode within a 32-bit integer (as basically a frame count plus a 3-bit framerate index).
 
 Frame count has a max value of 2592000, so needs 22 bits. So:
 
 Bits 0-21:  frame count
 Bit  22:    1 if negative
 Bits 23-24: 00 = 24, 01 = 25, 10 = 30nd, 11 = 30df
 Bit  25:    1 if video speed
 
 */

#import "F53Timecode-OSCAdditions.h"

@implementation F53Timecode (OSCAdditions)

- (UInt32) intValueForOSC
{
    SInt32 frames = [self framesFromZero];
    UInt32 value = abs(frames);
    
    if (frames < 0) value |= 1 << 22;
    
    F53Framerate *framerate = [self framerate];
    switch (framerate.framesPerSecond)
    {
        case 24:
            value |= 0 << 23;
            break;
        case 25:
            value |= 1 << 23;
            break;
        case 30:
            if (framerate.dropFrame)
                value |= 3 << 23;
            else
                value |= 2 << 23;
            break;
    }
    
    if (framerate.videoSpeed)
        value |= 1 << 25;
    
    return value;
}

+ (F53Timecode *) timecodeWithIntValueForOSC: (UInt32) intValue
{
    F53Framerate *targetFramerate;
    switch (intValue >> 23)
    {
        case 0: targetFramerate = [F53Framerate framerateWith24fps]; break;
        case 1: targetFramerate = [F53Framerate framerateWith25fps]; break;
        case 2: targetFramerate = [F53Framerate framerateWith30nondrop]; break;
        case 3: targetFramerate = [F53Framerate framerateWith30drop]; break;
        case 4: targetFramerate = [F53Framerate framerateWith23976fps]; break;
        case 5: targetFramerate = [F53Framerate framerateWith24975fps]; break;
        case 6: targetFramerate = [F53Framerate framerateWith2997nondrop]; break;
        case 7: targetFramerate = [F53Framerate framerateWith2997drop]; break;
    }
    
    F53Timecode *result = [F53Timecode timecodeWithFramerate:targetFramerate negative:NO hours:0 minutes:0 seconds:0 frames:0 bits:0];
    result.framesFromZero = intValue & 0x3fffff;
    return result;
}

@end
