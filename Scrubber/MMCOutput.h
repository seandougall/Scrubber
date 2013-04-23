//
//  MMCOutput.h
//  Scrubber
//
//  Created by Sean Dougall on 4/22/13.
//  Copyright (c) 2013 Figure 53. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SnoizeMIDI/SnoizeMIDI.h>

@interface MMCOutput : NSObject
{
    SMPortOutputStream *_output;
    IBOutlet NSTextField *_tcLabel;
}

- (IBAction) scrub:(NSSlider *)sender;

@end
