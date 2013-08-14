//
//  F53Timecode.m
//                - v2 -
//
//  Created by Sean Dougall on 2/27/12.
//  Copyright (c) 2012 Figure 53. All rights reserved.
//

#import "F53Timecode.h"

@interface F53Framerate ()

- (id)initWithFramesPerSecond:(int)fps videoSpeed:(BOOL)videoSpeed dropFrame:(BOOL)dropFrame;

/*
 F53Framerate takes care of any calculations that involve converting between seconds
 and frames. That way all framerate-related logic is separated from F53Timecode. In
 order to speed things up, rather than doing the same calculation over and over, the
 F53Framerate instance will cache the results of its most recent calculation.
 */

// Calculations for F53Timecode's internal use
- (SInt64) absoluteCommonTicksForNegative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits;
- (BOOL) negativeForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (int) hoursForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (int) minutesForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (int) secondsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (int) framesForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (int) bitsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;
- (double) bitsPerSecond;

// Caches to avoid redundant calculations for the above. No need to call these explicitly.
@property (nonatomic, assign) SInt64 cachedAbsoluteCommonTicks;
@property (nonatomic, assign) int *cachedComponents;
- (void) calculateComponentsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks;

@end

#pragma mark -

@implementation F53Framerate

+ (F53Framerate *) framerateWith2997nondrop
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:30 videoSpeed:YES dropFrame:NO] autorelease];
}

+ (F53Framerate *) framerateWith2997drop
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:30 videoSpeed:YES dropFrame:YES] autorelease];
}

+ (F53Framerate *) framerateWith30nondrop
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:30 videoSpeed:NO dropFrame:NO] autorelease];
}

+ (F53Framerate *) framerateWith30drop
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:30 videoSpeed:NO dropFrame:YES] autorelease];
}

+ (F53Framerate *) framerateWith24fps
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:24 videoSpeed:NO dropFrame:NO] autorelease];
}

+ (F53Framerate *) framerateWith23976fps
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:24 videoSpeed:YES dropFrame:NO] autorelease];
}

+ (F53Framerate *) framerateWith25fps
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:25 videoSpeed:NO dropFrame:NO] autorelease];
}

+ (F53Framerate *) framerateWith24975fps
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:25 videoSpeed:YES dropFrame:NO] autorelease];
}

+ (F53Framerate *) invalidFramerateMarker
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:-1 videoSpeed:NO dropFrame:NO] autorelease];
}

+ (F53Framerate *) anyFramerateMarker
{
    return [[[F53Framerate alloc] initWithFramesPerSecond:-2 videoSpeed:NO dropFrame:NO] autorelease];
}

- (int) index
{
    if ( self.framesPerSecond == 24 )
        return self.videoSpeed ? 0 : 1;
    if ( self.framesPerSecond == 25 )
        return self.videoSpeed ? 2 : 3;
    if ( self.framesPerSecond == 30 )
    {
        if ( self.videoSpeed )
            return self.dropFrame ? 5 : 4;
        else
            return self.dropFrame ? 7 : 6;
    }
    if ( self.isAnyFramerateMarker )
        return -2;
    return -1;
}

+ (F53Framerate *) framerateForIndex:(int)index
{
    switch ( index )
    {
        case 0: return [F53Framerate framerateWith23976fps];
        case 1: return [F53Framerate framerateWith24fps];
        case 2: return [F53Framerate framerateWith24975fps];
        case 3: return [F53Framerate framerateWith25fps];
        case 4: return [F53Framerate framerateWith2997nondrop];
        case 5: return [F53Framerate framerateWith2997drop];
        case 6: return [F53Framerate framerateWith30nondrop];
        case 7: return [F53Framerate framerateWith30drop];
        case -2: return [F53Framerate anyFramerateMarker];
        default: return [F53Framerate invalidFramerateMarker];
    }
}

- (id) initWithFramesPerSecond:(int)fps videoSpeed:(BOOL)videoSpeed dropFrame:(BOOL)dropFrame
{
    self = [super init];
    if ( self )
    {
        self.framesPerSecond = fps;
        self.videoSpeed = videoSpeed;
        if ( dropFrame && ( self.framesPerSecond != 30 ) )
        {
            NSLog( @"Warning: Tried to create a framerate object at %d fps drop-frame, which is impossible. Making non-drop instead.", self.framesPerSecond );
            self.dropFrame = NO;
        }
        else
        {
            self.dropFrame = dropFrame;
        }
        _cachedAbsoluteCommonTicks = -1;
        _cachedComponents = malloc( 6 * sizeof( int ) );
        for ( int i = 0; i < 6; i++ )
            _cachedComponents[i] = -1;
    }
    return self;
}

- (void) dealloc
{
    if ( _cachedComponents ) free( _cachedComponents );
    _cachedComponents = NULL;
    
    [super dealloc];
}

- (NSString *) description
{
    switch ( _framesPerSecond )
    {
        case -2: return @"Any framerate";
        case -1: return @"Invalid framerate";
        case 24: return _videoSpeed ? @"23.976 fps" : @"24 fps";
        case 25: return _videoSpeed ? @"24.975 fps" : @"25 fps";
        case 30:
            if ( _dropFrame )
                return _videoSpeed ? @"29.97 drop" : @"30 drop";
            else
                return _videoSpeed ? @"29.97 non-drop" : @"30 fps";
        default:
            return [NSString stringWithFormat:@"Unknown framerate (%d fps, %@ speed, %@drop)", _framesPerSecond, ( _videoSpeed ? @"video" : @"film" ), ( _dropFrame ? @"" : @"non-" )];
    }
}

#pragma mark - NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    return [[F53Framerate alloc] initWithFramesPerSecond:_framesPerSecond videoSpeed:_videoSpeed dropFrame:_dropFrame];
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:self.framesPerSecond forKey:@"F53FramerateFramesPerSecond"];
    [coder encodeBool:self.videoSpeed forKey:@"F53FramerateVideoSpeed"];
    [coder encodeBool:self.dropFrame forKey:@"F53FramerateDropFrame"];
}

- (id) initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if ( self )
    {
        self.framesPerSecond = [coder decodeIntegerForKey:@"F53FramerateFramesPerSecond"];
        self.videoSpeed = [coder decodeBoolForKey:@"F53FramerateVideoSpeed"];
        self.dropFrame = [coder decodeBoolForKey:@"F53FramerateDropFrame"];
    }
    return self;
}

#pragma mark - Assessment

- (BOOL) isInvalidFramerateMarker
{
    return ( _framesPerSecond == -1 );
}

- (BOOL) isAnyFramerateMarker
{
    return ( _framesPerSecond == -2 );
}

- (BOOL) isEquivalent:(F53Framerate *)otherFramerate
{
    if ( self.isInvalidFramerateMarker || otherFramerate.isInvalidFramerateMarker )
        return NO;
    if ( self.isAnyFramerateMarker || otherFramerate.isAnyFramerateMarker )
        return YES;
    return ( _framesPerSecond == otherFramerate->_framesPerSecond
            && _dropFrame == otherFramerate->_dropFrame );
}

- (BOOL) isEqual:(F53Framerate *)otherFramerate
{
    return ( _framesPerSecond == otherFramerate->_framesPerSecond &&
            _dropFrame == otherFramerate->_dropFrame &&
            _videoSpeed == otherFramerate->_videoSpeed );
}

#pragma mark - Calculations

- (SInt64) absoluteCommonTicksForNegative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits
{
    // There's not a whole lot of math coming up, but we may as well avoid doing it if we can.
    if ( negative == ( _cachedComponents[0] < 0 ) &&
        hours == _cachedComponents[1] &&
        minutes == _cachedComponents[2] &&
        seconds == _cachedComponents[3] &&
        frames == _cachedComponents[4] &&
        bits == _cachedComponents[5] )
    {
        return _cachedAbsoluteCommonTicks;
    }
    
    SInt32 totalFrames = ( ( hours * 60 + minutes ) * 60 + seconds ) * _framesPerSecond + frames;
    
    // Adjust for dropframe counting, if necessary
    if ( _dropFrame && _framesPerSecond == 30 )
    {
        totalFrames -= 2;
        totalFrames = totalFrames - 2 * ( totalFrames / 1800 ) + 2 * ( totalFrames / 18000 );
        totalFrames += 2;
    }
    
    [self calculateComponentsForAbsoluteCommonTicks:self.commonTicksPerBit * ( totalFrames * 80 + bits )];
    
    return _cachedAbsoluteCommonTicks;
}

- (void) calculateComponentsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    if ( absoluteCommonTicks != _cachedAbsoluteCommonTicks )
    {
        _cachedAbsoluteCommonTicks = absoluteCommonTicks;
        
        // First extract sign and subframe bits; those aren't dependent on framerate.
        SInt32 temp = labs( absoluteCommonTicks / self.commonTicksPerBit );
        _cachedComponents[0] = ( absoluteCommonTicks < 0 ? -1 : 1 );  // sign
        _cachedComponents[5] = temp % 80;                           // bits
        temp /= 80;
        
        // Next, make any dropframe-related adjustments.
        if ( _dropFrame && _framesPerSecond == 30 )
            temp += 18 * ( temp / 17982 ) + 2 * ( ( ( temp % 17982 ) - 2 ) / 1798 );    // Uff da.
        
        // Now go on to extract the remaining values.
        _cachedComponents[4] = temp % _framesPerSecond;             // frames
        temp /= _framesPerSecond;
        _cachedComponents[3] = temp % 60;                           // seconds
        temp /= 60;
        _cachedComponents[2] = temp % 60;                           // minutes
        temp /= 60;
        _cachedComponents[1] = temp % 24;                           // hours
    }
}

- (BOOL) negativeForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[0];
}

- (int) hoursForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[1];
}

- (int) minutesForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[2];
}

- (int) secondsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[3];
}

- (int) framesForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[4];
}

- (int) bitsForAbsoluteCommonTicks:(SInt64)absoluteCommonTicks
{
    [self calculateComponentsForAbsoluteCommonTicks:absoluteCommonTicks];
    return _cachedComponents[5];
}

- (double) bitsPerSecond
{
    double result = (double)( 80 * _framesPerSecond );
    if ( _videoSpeed )
        result /= 1.001;
    return result;
}

- (SInt64) commonTicksPerBit
{
    switch ( self.framesPerSecond )
    {
        case 30:
            return ( self.videoSpeed ? 20020 : 20000 );
        case 25:
            return ( self.videoSpeed ? 24024 : 24000 );
        case 24:
            return ( self.videoSpeed ? 25025 : 25000 );
        default:
            return -1;
    }
}

- (SInt64) commonTicksPerFrame
{
    switch ( self.framesPerSecond )
    {
        case 30:
            return ( self.videoSpeed ? 1601600 : 1600000 );
        case 25:
            return ( self.videoSpeed ? 1921920 : 1920000 );
        case 24:
            return ( self.videoSpeed ? 2002000 : 2000000 );
        default:
            return -1;
    }
}

@end


#pragma mark -


@interface F53Timecode ()

- (void) setNegative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits;
@property (assign) UInt64 cachedLTCRepresentation;
@property (assign) SInt32 framesFromZeroForCachedLTCRepresentation;

@end


#pragma mark -


@implementation F53Timecode

- (id) init
{
    self = [super init];
    if ( self )
    {
        self.absoluteCommonTicks = 0;
        self.framerate = [F53Framerate framerateWith2997nondrop];
        self.cachedLTCRepresentation = 0;
        self.framesFromZeroForCachedLTCRepresentation = -1;
    }
    return self;
}

- (id) initWithFramerate:(F53Framerate *)framerate negative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits
{
    self = [super init];
    if ( self )
    {
        self.absoluteCommonTicks = 0;
        self.framerate = framerate;
        [self setNegative:negative hours:hours minutes:minutes seconds:seconds frames:frames bits:bits];
    }
    return self;
}

+ (F53Timecode *) timecodeWithFramerate:(F53Framerate *)framerate negative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits
{
    return [[[F53Timecode alloc] initWithFramerate:framerate negative:negative hours:hours minutes:minutes seconds:seconds frames:frames bits:bits] autorelease];
}

+ (F53Timecode *) timecodeWithFramerate:(F53Framerate *)framerate stringRepresentation:(NSString *)stringRepresentation
{
    F53Timecode *result = [[F53Timecode alloc] init];
    result.framerate = framerate;
    result.stringRepresentation = stringRepresentation;
    return [result autorelease];
}

+ (F53Timecode *) invalidTimecodeMarker
{
    return [[[F53Timecode alloc] initWithFramerate:[F53Framerate invalidFramerateMarker] negative:NO hours:0 minutes:0 seconds:0 frames:0 bits:0] autorelease];
}

- (NSComparisonResult) compare:(F53Timecode *)otherTimecode
{
    if ( self.commonTicksFromZero > otherTimecode.commonTicksFromZero )
        return NSOrderedDescending;
    if ( self.commonTicksFromZero < otherTimecode.commonTicksFromZero )
        return NSOrderedAscending;
    return NSOrderedSame;
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.framerate forKey:@"F53TimecodeFramerate"];
    [coder encodeInt64:self.commonTicksFromZero forKey:@"F53TimecodeCommonTicks"];
}

- (id) initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if ( self )
    {
        // F53Timecode v2
        if ( [coder containsValueForKey:@"F53TimecodeFramerate"] )
        {
            self.framerate = [coder decodeObjectForKey:@"F53TimecodeFramerate"];
            self.commonTicksFromZero = [coder decodeInt64ForKey:@"F53TimecodeCommonTicks"];
        }
        // F53Timecode v1
        else if ( [coder containsValueForKey:@"F53TimecodeHH"] )
        {
            int hours = [coder decodeIntForKey:@"F53TimecodeHH"];
            int minutes = [coder decodeIntForKey:@"F53TimecodeMM"];
            int seconds = [coder decodeIntForKey:@"F53TimecodeSS"];
            int frames = [coder decodeIntForKey:@"F53TimecodeFF"];
            int bits = [coder decodeIntForKey:@"F53TimecodeBits"];
            int fps = [coder decodeIntForKey:@"F53TimecodeFramerate.fps"];
            BOOL videoSpeed = [coder decodeBoolForKey:@"F53TimecodeFramerate.videoSpeed"];
            BOOL dropFrame = [coder decodeBoolForKey:@"F53TimecodeFramerate.dropFrame"];
            self.framerate = [[F53Framerate alloc] initWithFramesPerSecond:fps videoSpeed:videoSpeed dropFrame:dropFrame];
            [self setNegative:NO hours:hours minutes:minutes seconds:seconds frames:frames bits:bits];
        }
        // CTTimecode (from legacy workspaces)
        else if ( [coder containsValueForKey:@"CTTimecodeHH"] )
        {
            int hours = [coder decodeIntForKey:@"CTTimecodeHH"];
            int minutes = [coder decodeIntForKey:@"CTTimecodeMM"];
            int seconds = [coder decodeIntForKey:@"CTTimecodeSS"];
            int frames = [coder decodeIntForKey:@"CTTimecodeFF"];
            int bits = [coder decodeIntForKey:@"CTTimecodeBits"];
            int fps = [coder decodeIntForKey:@"CTTimecodeFramerate.fps"];
            BOOL videoSpeed = [coder decodeBoolForKey:@"CTTimecodeFramerate.videoSpeed"];
            BOOL dropFrame = [coder decodeBoolForKey:@"CTTimecodeFramerate.dropFrame"];
            self.framerate = [[F53Framerate alloc] initWithFramesPerSecond:fps videoSpeed:videoSpeed dropFrame:dropFrame];
            [self setNegative:NO hours:hours minutes:minutes seconds:seconds frames:frames bits:bits];
        }
    }
    return self;
}

#pragma mark - NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    F53Timecode *newTimecode = [[F53Timecode alloc] init];
    newTimecode.framerate = self.framerate;
    newTimecode.absoluteCommonTicks = self.absoluteCommonTicks;
    return newTimecode;
}

#pragma mark - Accessors

- (BOOL) negative
{
    return ( _absoluteCommonTicks < 0 );
}

- (void) setNegative:(BOOL)negative
{
    [self setNegative:negative hours:self.hours minutes:self.minutes seconds:self.seconds frames:self.frames bits:self.bits];
}

- (int) hours
{
    return [_framerate hoursForAbsoluteCommonTicks:_absoluteCommonTicks];
}

- (void) setHours:(int)hours
{
    [self setNegative:self.negative hours:hours minutes:self.minutes seconds:self.seconds frames:self.frames bits:self.bits];
}

- (int) minutes
{
    return [_framerate minutesForAbsoluteCommonTicks:_absoluteCommonTicks];
}

- (void) setMinutes:(int)minutes
{
    [self setNegative:self.negative hours:self.hours minutes:minutes seconds:self.seconds frames:self.frames bits:self.bits];
}

- (int) seconds
{
    return [_framerate secondsForAbsoluteCommonTicks:_absoluteCommonTicks];
}

- (void) setSeconds:(int)seconds
{
    [self setNegative:self.negative hours:self.hours minutes:self.minutes seconds:seconds frames:self.frames bits:self.bits];
}

- (int) frames
{
    return [_framerate framesForAbsoluteCommonTicks:_absoluteCommonTicks];
}

- (void) setFrames:(int)frames
{
    if ( frames < 0 || frames >= _framerate.framesPerSecond )
        self.framesFromZero += ( frames - self.frames );
    else
        [self setNegative:self.negative hours:self.hours minutes:self.minutes seconds:self.seconds frames:frames bits:self.bits];
}

- (int) bits
{
    return [_framerate bitsForAbsoluteCommonTicks:_absoluteCommonTicks];
}

- (void) setBits:(int)bits
{
    [self setNegative:self.negative hours:self.hours minutes:self.minutes seconds:self.seconds frames:self.frames bits:bits];
}

- (void) setNegative:(BOOL)negative hours:(int)hours minutes:(int)minutes seconds:(int)seconds frames:(int)frames bits:(int)bits
{
    _absoluteCommonTicks = [_framerate absoluteCommonTicksForNegative:negative hours:hours minutes:minutes seconds:seconds frames:frames bits:bits];
}

- (void) convertToFramerate:(F53Framerate *)framerate usingMethod:(F53FramerateConversionMethod)method
{
    if ( method == kF53FramerateConvertPreservingNumericalValues )
    {
        SInt64 newAbsoluteCommonTicks = [framerate absoluteCommonTicksForNegative:self.negative hours:self.hours minutes:self.minutes seconds:self.seconds frames:self.frames bits:self.bits];
        self.framerate = framerate;
        _absoluteCommonTicks = newAbsoluteCommonTicks;
    }
    else if ( method == kF53FramerateConvertPreservingFrameCountFromZero )
    {
        SInt32 oldFramesFromZero = self.framesFromZero;
        self.framerate = framerate;
        self.framesFromZero = oldFramesFromZero;
    }
    else if ( method == kF53FramerateConvertPreservingRealTimeFromZero )
    {
        self.framerate = framerate;
    }
}

- (SInt32) framesFromZero
{
    return _absoluteCommonTicks / _framerate.commonTicksPerFrame;
}

- (void) setFramesFromZero:(SInt32)framesFromZero
{
    _absoluteCommonTicks = framesFromZero * _framerate.commonTicksPerFrame;
}

- (double) secondsFromZero
{
    return (double)_absoluteCommonTicks / kF53TimecodeCommonTicksPerSecond;
}

- (void) setSecondsFromZero:(double)secondsFromZero
{
    _absoluteCommonTicks = (SInt64)( secondsFromZero * kF53TimecodeCommonTicksPerSecond );
}

- (SInt64) commonTicksFromZero
{
    return _absoluteCommonTicks;
}

- (void) setCommonTicksFromZero:(SInt64)commonTicksFromZero
{
    _absoluteCommonTicks = commonTicksFromZero;
}

- (SInt32) framesFromTimecode:(F53Timecode *)otherTimecode
{
    return self.framesFromZero - otherTimecode.framesFromZero;
}

- (double) secondsFromTimecode:(F53Timecode *)otherTimecode
{
    return self.secondsFromZero - otherTimecode.secondsFromZero;
}

#pragma mark - String

- (NSString *) description
{
    return self.stringRepresentationWithBitsAndFramerate;
}

- (NSString *) stringRepresentation
{
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d",
            self.hours,
            self.minutes,
            self.seconds,
            (_framerate.dropFrame ? @";" : @":"),
            self.frames];
}

- (BOOL) scanInt:(int *)value fromScanner:(NSScanner *)scanner
{
    if ( scanner.isAtEnd )
    {
        *value = 0;
        return YES;
    }
    [scanner scanInt:value];
    if ( scanner.isAtEnd ) return YES;
    scanner.scanLocation++;
    return ( scanner.isAtEnd );
}

- (void) setStringRepresentation:(NSString *)stringRepresentation
{
    if ( [stringRepresentation length] == 0)
        return;
    
    BOOL negative = NO;
    int hours = 0, minutes = 0, seconds = 0, frames = 0, bits = 0;
    
    NSScanner *s = [NSScanner scannerWithString:stringRepresentation];
    if ( [stringRepresentation characterAtIndex:0] == '-' )
    {
        negative = YES;
        s.scanLocation = 1;
    }
    
    [self scanInt:&hours fromScanner:s];
    [self scanInt:&minutes fromScanner:s];
    [self scanInt:&seconds fromScanner:s];
    [self scanInt:&frames fromScanner:s];
    [self scanInt:&bits fromScanner:s];
    
    // If a huge number was entered, treat it as a full string, e.g. "1042718" -> 1:04:27:18.
    // If a separator and another number were found, make that number the bits (instead of the minutes as previously scanned in). e.g. "1042718.79" -> "1:04:27:18/79".
    if ( hours >= 1000 )
    {
        int temp = hours;
        bits = minutes;
        frames = temp % 100;
        temp /= 100;
        seconds = temp % 100;
        temp /= 100;
        minutes = temp % 100;
        temp /= 100;
        hours = temp % 24;
    }
    
    [self setNegative:negative hours:hours minutes:minutes seconds:seconds frames:frames bits:bits];
}

- (NSString *) stringRepresentationWithBits
{
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d/%02d",
            self.hours,
            self.minutes,
            self.seconds,
            (_framerate.dropFrame ? @";" : @":"),
            self.frames,
            self.bits];
}

- (void) setStringRepresentationWithBits:(NSString *)stringRepresentationWithBits
{
    self.stringRepresentation = stringRepresentationWithBits;
}

- (NSString *) stringRepresentationWithBitsAndFramerate
{
    return [NSString stringWithFormat:@"%d:%02d:%02d%@%02d/%02d@%@",
            self.hours,
            self.minutes,
            self.seconds,
            (_framerate.dropFrame ? @";" : @":"),
            self.frames,
            self.bits,
            self.framerate];
}

#pragma mark - LTC

- (UInt64) LTCRepresentation
{
    if ( self.framesFromZero == _framesFromZeroForCachedLTCRepresentation )
        return _cachedLTCRepresentation;
    
    // LTC does not work for negative timecode.
    if ( self.negative )
        return 0x0000000000000000;
    
    // Ever-reliable source on LTC structure: http://en.wikipedia.org/wiki/Linear_timecode
    
    // Start with user bits that spell 'F53!', then fill in the data
    UInt64 result = 0x4060385030302010; 
    result |= (UInt64)( self.frames % 10 );
    result |= (UInt64)( self.frames / 10 ) << 8;
    if ( self.framerate.dropFrame ) result |= 1 << 10;
    result |= (UInt64)( self.seconds % 10 ) << 16;
    result |= (UInt64)( self.seconds / 10 ) << 24;
    result |= (UInt64)( self.minutes % 10 ) << 32;
    result |= (UInt64)( self.minutes / 10 ) << 40;
    int hours = self.hours % 24;
    result |= (UInt64)( hours % 10 ) << 48;
    result |= (UInt64)( hours / 10 ) << 56;
    
    // Calculate the parity bit such that the total number of 1s is even (which means
    // the number of 1s in this representation should be _odd_, since there's an odd
    // number of 1s in the sync word that comes after it).
    UInt64 parity = ( result & 0xffffffff ) ^ ( result >> 32 );
    parity = ( parity & 0xffff ) ^ ( parity >> 16 );
    parity = ( parity & 0xff ) ^ ( parity >> 8 );
    parity = ( parity & 0xf ) ^ ( parity >> 4 );
    parity = ( parity & 0x3 ) ^ ( parity >> 2 );
    parity = ( parity & 0x1 ) ^ ( parity >> 1 );
    if ( parity == 0 ) result |= 1 << 27;
    
    _cachedLTCRepresentation = result;
    _framesFromZeroForCachedLTCRepresentation = self.framesFromZero;
    
    return result;
}

@end
