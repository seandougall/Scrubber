//
//  F53Timecode-OSCAdditions.m
//
//  Created by Sean Dougall on 2/16/11.
//
//  Copyright (c) 2011 Figure 53 LLC, http://figure53.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    
    F53Framerate framerate = [self framerate];
    switch (framerate.fps)
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
    F53Framerate targetFramerate;
    switch (intValue >> 23)
    {
        case 0: targetFramerate = F53Framerate24; break;
        case 1: targetFramerate = F53Framerate25; break;
        case 2: targetFramerate = F53Framerate30nd; break;
        case 3: targetFramerate = F53Framerate30df; break;
        case 4: targetFramerate = F53Framerate23976; break;
        case 5: targetFramerate = F53Framerate24975; break;
        case 6: targetFramerate = F53Framerate2997nd; break;
        case 7: targetFramerate = F53Framerate2997df; break;
    }
    
    F53Timecode *result = [F53Timecode timecodeWithFramerate:targetFramerate hh:0 mm:0 ss:0 ff:intValue & 0x3fffff];
    return result;
}

@end
