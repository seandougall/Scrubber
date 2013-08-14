//
//  F53Timecode-MTCAdditions.m
//
//  Created by Sean Dougall on 2/21/11.
//  Copyright 2011 Figure 53. All rights reserved.
//

#import "F53Timecode-MTCAdditions.h"


@implementation F53Timecode (MTCAdditions)

+ (F53Framerate *) framerateForMTCIndex:(F53MTCFramerateIndex)index
{
    switch ( index )
    {
        case kF53MTCFramerateIndex24fps:
            return [F53Framerate framerateWith24fps];
        case kF53MTCFramerateIndex25fps:
            return [F53Framerate framerateWith25fps];
        case kF53MTCFramerateIndex30nd:
            return [F53Framerate framerateWith2997nondrop];
        case kF53MTCFramerateIndex30df:
            return [F53Framerate framerateWith2997drop];
        case kF53MTCFramerateIndexInvalid:
            NSLog( @"index %d invalid", index );
            return [F53Framerate invalidFramerateMarker];
    }
    
    return [F53Framerate invalidFramerateMarker];
}

+ (F53Framerate *) framerateForMTCIndex:(F53MTCFramerateIndex)index pullDown:(BOOL)pullDown
{
    switch ( index )
    {
        case kF53MTCFramerateIndex24fps:
            return pullDown ? [F53Framerate framerateWith23976fps] : [F53Framerate framerateWith24fps];
        case kF53MTCFramerateIndex25fps:
            return pullDown ? [F53Framerate framerateWith24975fps] : [F53Framerate framerateWith25fps];
        case kF53MTCFramerateIndex30nd:
            return pullDown ? [F53Framerate framerateWith2997nondrop] : [F53Framerate framerateWith30nondrop];
        case kF53MTCFramerateIndex30df:
            return pullDown ? [F53Framerate framerateWith2997drop] : [F53Framerate framerateWith30drop];
        case kF53MTCFramerateIndexInvalid:
            return [F53Framerate invalidFramerateMarker];
    }
    
    return [F53Framerate invalidFramerateMarker];
}

+ (F53MTCFramerateIndex) mtcIndexForFramerate:(F53Framerate *)framerate
{
    switch ( framerate.framesPerSecond )
    {
        case 24: 
            return kF53MTCFramerateIndex24fps;
        case 25:
            return kF53MTCFramerateIndex25fps;
        case 30:
            return framerate.dropFrame ? kF53MTCFramerateIndex30df : kF53MTCFramerateIndex30nd;
    }
    return kF53MTCFramerateIndexInvalid;
}

+ (F53Timecode *) timecodeWithMTCFramerateIndex:(F53MTCFramerateIndex)index
                                             hh:(int)hh
                                             mm:(int)mm
                                             ss:(int)ss
                                             ff:(int)ff
{
    if ( index == kF53MTCFramerateIndexInvalid )
        return [F53Timecode invalidTimecodeMarker];
    
    return [F53Timecode timecodeWithFramerate:[F53Timecode framerateForMTCIndex:index] negative:NO hours:hh minutes:mm seconds:ss frames:ff bits:0];
}


- (void) setHighHH:(int)h
{
    self.framerate = [F53Timecode framerateForMTCIndex:((h & 0x06) >> 1)];
    self.hours = (h & 0x01) << 4 | (self.hours & 0x0f);
    self.framesFromZero++;
}

- (void) setLowHH:(int)h
{
    self.hours = (self.hours & 0xf0) | (h & 0x0f);
}

- (void) setHighMM:(int)m
{
    self.minutes = (m & 0x0f) << 4 | (self.minutes & 0x0f);
}

- (void) setLowMM:(int)m
{
    self.minutes = (self.minutes & 0xf0) | (m & 0x0f);
}

- (void) setHighSS:(int)s
{
    self.seconds = (s & 0x0f) << 4 | (self.seconds & 0x0f);
}

- (void) setLowSS:(int)s
{
    self.seconds = (self.seconds & 0xf0) | (s & 0x0f);
}

- (void) setHighFF:(int)f
{
    self.frames = (f & 0x0f) << 4 | (self.frames & 0x0f);
}

- (void) setLowFF:(int)f
{
    self.framesFromZero++;
    self.frames = (self.frames & 0xf0) | (f & 0x0f);
}

@end
