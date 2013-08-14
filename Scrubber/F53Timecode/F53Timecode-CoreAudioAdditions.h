//
//  F53TimecodeCoreAudioExt.h
//
//  Created by Sean Dougall on 9/13/08.
//  Copyright 2008-2011 Figure 53, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/CoreAudioClock.h>

#import "F53Timecode.h"

@interface F53Timecode (CoreAudioAdditions) 

// timecode conversion
+ (F53Timecode *) timecodeWithSMPTETime:(SMPTETime)smpteTime;
- (SMPTETime) SMPTETime;

// framerate conversion
+ (F53Framerate *) framerateForCASMPTEType:(UInt32)smpteType;
+ (UInt32) CASMPTETypeForFramerate:(F53Framerate *)framerate;

@end
