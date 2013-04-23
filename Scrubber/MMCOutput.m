//
//  MMCOutput.m
//  Scrubber
//
//  Created by Sean Dougall on 4/22/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import "MMCOutput.h"
#import "F53Timecode.h"

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
    F53Timecode *tc = [F53Timecode timecodeWithFramerate:F53Framerate2997nd hh:1 mm:0 ss:0 ff:0];
    [tc addSeconds:10.0 * 60.0 * [sender doubleValue]];
    [self _sendTimecode:tc];
}

- (void) _sendTimecode:(F53Timecode *)tc
{
    char tcMode;
    if ( tc.framerate.fps == 24 )
    {
        tcMode = 0;
    }
    else if ( tc.framerate.fps == 25 )
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
    bytes[7] = ( tcMode << 5 ) | ( tc.hh );
    bytes[8] = tc.mm;
    bytes[9] = tc.ss;
    bytes[10] = tc.ff;
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
