//
//  MMCOutput.m
//  Scrubber
//
//  Created by Sean Dougall on 4/22/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "MMCOutput.h"
#import "F53Timecode.h"
#import "F53Timecode-MTCAdditions.h"

@interface MMCOutput ()

- (void) _sendTimecode:(F53Timecode *)tc;

@end

#pragma mark -


@implementation MMCOutput

- (void) awakeFromNib
{
    _output = [[SMPortOutputStream alloc] init];
    SMDestinationEndpoint *endpoint = [SMDestinationEndpoint destinationEndpointWithName:@"IAC Bus 1"];
    if ( endpoint )
        [_output setEndpoints:[NSSet setWithObject:endpoint]];
    else
        NSLog( @"Endpoint not found. Possibilities: %@", [SMDestinationEndpoint destinationEndpoints] );
}

- (void) dealloc
{
    [_output release];
    _output = nil;
    
    [super dealloc];
}

- (IBAction) scrub:(NSSlider *)sender
{
    F53Timecode *tc = [F53Timecode timecodeWithFramerate:[F53Framerate framerateWith2997nondrop] negative:NO hours:1 minutes:0 seconds:0 frames:0 bits:0];
    tc.secondsFromZero += 10.0 * 60.0 * [sender doubleValue];
    _startTimecode = [tc copy];
    _mtcTimecode = _startTimecode;
    [self _sendTimecode:tc];
}

- (IBAction) play:(id)sender
{
    if ( !_running )
    {
        __block NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
        if ( !_mtcQueue )
        {
            _mtcQueue = dispatch_queue_create( "MTC", 0 );
            _mtcStopped = dispatch_semaphore_create( 0 );
        }
        _mtcTimecode = [_startTimecode copy];
        _running = YES;
        dispatch_async( _mtcQueue, ^{
            while ( _running )
            {
                _qfIndex = ( _qfIndex + 1 ) % 8;
                if ( _qfIndex == 0 || _qfIndex == 4 )
                    _mtcTimecode.framesFromZero++;
                [self _sendQuarterFrame:_qfIndex forTimecode:_mtcTimecode];
                time += (double)[_mtcTimecode.framerate commonTicksPerBit] * 20. / (double)kF53TimecodeCommonTicksPerSecond;
                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceReferenceDate:time]];
            }
            dispatch_semaphore_signal( _mtcStopped );
        });
    }
    else
    {
        NSLog( @"MTC already running." );
    }
}

- (IBAction) stop:(id)sender
{
    _running = NO;
}

- (IBAction) stopAndRewind:(id)sender
{
    _running = NO;
    dispatch_semaphore_wait( _mtcStopped, DISPATCH_TIME_FOREVER );
    [self _sendTimecode:_startTimecode];
}

- (IBAction) restart:(id)sender
{
    _running = NO;
    dispatch_semaphore_wait( _mtcStopped, DISPATCH_TIME_FOREVER );
    [self play:sender];
}

- (void) _sendQuarterFrame:(int)qfIndex forTimecode:(F53Timecode *)tc
{
    if ( !tc )
    {
        NSLog( @"Error: No timecode" );
        return;
    }
    unsigned payloadLength = 2;
    char *bytes = malloc( payloadLength );
    bytes[0] = 0xf1;
    switch ( qfIndex )
    {
        case 0: bytes[1] = 0x00 | ( tc.frames & 0x0f ); break;
        case 1: bytes[1] = 0x10 | ( tc.frames >> 4 ); break;
        case 2: bytes[1] = 0x20 | ( tc.seconds & 0x0f ); break;
        case 3: bytes[1] = 0x30 | ( tc.seconds >> 4 ); break;
        case 4: bytes[1] = 0x40 | ( tc.minutes & 0x0f ); break;
        case 5: bytes[1] = 0x50 | ( tc.minutes >> 4 ); break;
        case 6: bytes[1] = 0x60 | ( tc.hours & 0x0f ); break;
        case 7:
            bytes[1] = 0x70;
            bytes[1] |= [F53Timecode mtcIndexForFramerate:tc.framerate] << 1;
            bytes[1] |= tc.hours >> 4 ;
            break;
    }

    NSData *payload = [NSData dataWithBytes:(const void *)bytes length:payloadLength];
    SMSystemExclusiveMessage *msg = [[SMSystemExclusiveMessage systemExclusiveMessageWithTimeStamp:0 // dummy timestamp
                                                                                              data:payload] retain];
    free( bytes );
    [_output takeMIDIMessages:@[ msg ]];
    
    [_tcLabel setStringValue:[tc stringRepresentation]];
}

- (void) _sendTimecode:(F53Timecode *)tc
{
    char tcMode;
    if ( tc.framerate.framesPerSecond == 24 )
    {
        tcMode = 0;
    }
    else if ( tc.framerate.framesPerSecond == 25 )
    {
        tcMode = 1;
    }
    else
    {
        if ( tc.framerate.dropFrame )
        {
            tcMode = 2;
        }
        else
        {
            tcMode = 3;
        }
    }
    
    unsigned payloadLength = 13;
    char *bytes = malloc( payloadLength );
    bytes[0] = 0xf0;
    bytes[1] = 0x7f;
    bytes[2] = 0x7f; // device ID: all-
    bytes[3] = 0x06;
    bytes[4] = 0x44;
    bytes[5] = 0x06;
    bytes[6] = 0x01;
    bytes[7] = ( tcMode << 5 ) | ( tc.hours );
    bytes[8] = tc.minutes;
    bytes[9] = tc.seconds;
    bytes[10] = tc.frames;
    bytes[11] = tc.bits;
    bytes[12] = 0xf7;
    NSData *payload = [NSData dataWithBytes:(const void *)bytes length:payloadLength];
    SMSystemExclusiveMessage *msg = [[SMSystemExclusiveMessage systemExclusiveMessageWithTimeStamp:0 // dummy timestamp
                                                                                              data:payload] retain];
    free( bytes );
    [_output takeMIDIMessages:@[ msg ]];
    
    [_tcLabel setStringValue:[tc stringRepresentation]];
}

@end
