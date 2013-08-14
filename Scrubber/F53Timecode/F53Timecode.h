//
//  F53Timecode.h
//                - v2 -
//
//  Created by Sean Dougall on 2/27/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

/*
 
 Version 2 of F53Timecode centers around "common ticks", an integer representation
 of the absolute time value of the timecode, accurate enough to evenly divide TC
 bits in any of the major framerates.
 
 */



#import <Foundation/Foundation.h>

// 48000000 common ticks per second
// (evenly divides all framerates down to the subframe bit)
#define kF53TimecodeCommonTicksPerSecond 48000000

// Framerate indices -- these match kSMPTETimeType* (all except 24.975, for which no equivalent exists).
#define kF53FramerateIndex24         0
#define kF53FramerateIndex25         1
#define kF53FramerateIndex30Drop     2
#define kF53FramerateIndex30         3
#define kF53FramerateIndex2997       4
#define kF53FramerateIndex2997Drop   5
#define kF53FramerateIndex23976      11
#define kF53FramerateIndex24975      12

typedef enum {
    kF53FramerateConvertPreservingNumericalValues,      // e.g. 1:00:00:00 @24 fps -> "1, 0, 0, 0" -> 1:00:00:00 @29.97 non-drop
    kF53FramerateConvertPreservingFrameCountFromZero,   // e.g. 1:00:00:00 @24 fps -> 86400 frames -> 0:48:00:00 @29.97 non-drop
    kF53FramerateConvertPreservingRealTimeFromZero      // e.g. 1:00:00:00 @24 fps -> 3600 seconds -> 0:59:56:12 @29.97 non-drop
} F53FramerateConversionMethod;


#pragma mark -


@interface F53Framerate : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) int framesPerSecond;
@property (nonatomic, assign) BOOL videoSpeed;
@property (nonatomic, assign) BOOL dropFrame;

+ (F53Framerate *) framerateWith2997nondrop;
+ (F53Framerate *) framerateWith2997drop;
+ (F53Framerate *) framerateWith30nondrop;
+ (F53Framerate *) framerateWith30drop;
+ (F53Framerate *) framerateWith24fps;
+ (F53Framerate *) framerateWith23976fps;
+ (F53Framerate *) framerateWith25fps;
+ (F53Framerate *) framerateWith24975fps;
+ (F53Framerate *) invalidFramerateMarker;
+ (F53Framerate *) anyFramerateMarker;

- (int) index;
+ (F53Framerate *) framerateForIndex:(int)index;

@property (readonly) BOOL isInvalidFramerateMarker;
@property (readonly) BOOL isAnyFramerateMarker;

@property (readonly) SInt64 commonTicksPerBit;

- (BOOL) isEquivalent:(F53Framerate *)framerate; ///< Doesn't need to match videoSpeed parameter; this just tests whether the LTC or MTC data would be the same (which doesn't factor in video vs film speed).
- (BOOL) isEqual:(F53Framerate *)otherFramerate; ///< Tests for full equality, including for videoSpeed. More often than not, you should use -isEquivalent: instead.

@end


#pragma mark -


@interface F53Timecode : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) SInt64 absoluteCommonTicks; ///< Generally for F53Timecode's use only, but accessible just in case.

@property (nonatomic, copy) F53Framerate *framerate;

// Timecode components
/*
 Note: While you _can_ set these properties after initially creating a timecode object,
 in most cases there are better ways to go about mutation, such as the framesFromZero and
 secondsFromZero properties.
 */

@property (nonatomic, assign) BOOL negative;
@property (nonatomic, assign) int hours;
@property (nonatomic, assign) int minutes;
@property (nonatomic, assign) int seconds;
@property (nonatomic, assign) int frames;
@property (nonatomic, assign) int bits;

// Timing accessors
/*
 Use these to perform calculations on a timecode. For example, you can add exactly one frame
 with:
    tc.framesFromZero++;
 Or you can add 30 seconds of real time, which may be a fractional number of frames, with:
    tc.secondsFromZero -= 30.0;
 */

@property (nonatomic, assign) SInt32 framesFromZero;
@property (nonatomic, assign) double secondsFromZero;
@property (nonatomic, assign) SInt32 bitsFromZero;
@property (nonatomic, assign) SInt64 commonTicksFromZero;
- (SInt32) framesFromTimecode:(F53Timecode *)otherTimecode;
- (double) secondsFromTimecode:(F53Timecode *)otherTimecode;
- (NSComparisonResult) compare:(F53Timecode *)otherTimecode;

// Creating and managing
- (id) initWithFramerate:(F53Framerate *)framerate negative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits;
+ (F53Timecode *) timecodeWithFramerate:(F53Framerate *)framerate negative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits;
+ (F53Timecode *) timecodeWithFramerate:(F53Framerate *)framerate stringRepresentation:(NSString *)stringRepresentation;
+ (F53Timecode *) invalidTimecodeMarker;
- (void) convertToFramerate:(F53Framerate *)framerate usingMethod:(F53FramerateConversionMethod)method;

// Formatting
@property (nonatomic, assign) NSString *stringRepresentation;
@property (nonatomic, assign) NSString *stringRepresentationWithBits;
@property (readonly) NSString *stringRepresentationWithBitsAndFramerate;

// LTC
@property (readonly) UInt64 LTCRepresentation;    ///< Does not include the 16-bit sync word at the end of each frame.

@end
