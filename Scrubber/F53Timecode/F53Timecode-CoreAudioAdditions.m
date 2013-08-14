//
//  F53Timecode-CoreAudioAdditions.m
//
//  Created by Sean Dougall on 9/13/08.
//  Copyright 2008-2011 Figure 53, LLC. All rights reserved.
//

#import "F53Timecode-CoreAudioAdditions.h"

@implementation F53Timecode (CoreAudioAdditions)

+ (F53Timecode *) timecodeWithSMPTETime:(SMPTETime)smpteTime
{
	int hh = smpteTime.mHours;
	int mm = smpteTime.mMinutes;
	int ss = smpteTime.mSeconds;
	int ff = smpteTime.mFrames;
	int bits = smpteTime.mSubframes;
	int numBits = smpteTime.mSubframeDivisor;
	int type = smpteTime.mType;
	F53Framerate *fps;
	bits = (int)(((float)bits/numBits)*80.0);
	
	switch ( type )
    {
		case kSMPTETimeType2398:	fps = [F53Framerate framerateWith23976fps]; break;
		case kSMPTETimeType24:		fps = [F53Framerate framerateWith24fps]; break;
		case kSMPTETimeType25:		fps = [F53Framerate framerateWith25fps]; break;
		case kSMPTETimeType2997:	fps = [F53Framerate framerateWith2997nondrop]; break;
		case kSMPTETimeType2997Drop:fps = [F53Framerate framerateWith2997drop]; break;
		case kSMPTETimeType30:		fps = [F53Framerate framerateWith30nondrop]; break;
		case kSMPTETimeType30Drop:	fps = [F53Framerate framerateWith30drop]; break;
			// The following timecode rates don't exist in the real world.
			// Handling them just because Apple decided to toss in these constants.
		case kSMPTETimeType50:		fps = [F53Framerate framerateWith25fps]; bits = (numBits*ff+bits)/2; ff = bits/numBits; bits %= numBits; break;
		case kSMPTETimeType5994:	fps = [F53Framerate framerateWith2997nondrop]; bits = (numBits*ff+bits)/2; ff = bits/numBits; bits %= numBits; break;
		case kSMPTETimeType5994Drop:fps = [F53Framerate framerateWith2997drop]; bits = (numBits*ff+bits)/2; ff = bits/numBits; bits %= numBits; break;
		case kSMPTETimeType60:		fps = [F53Framerate framerateWith30nondrop]; bits = (numBits*ff+bits)/2; ff = bits/numBits; bits %= numBits; break;
		case kSMPTETimeType60Drop:	fps = [F53Framerate framerateWith30drop]; bits = (numBits*ff+bits)/2; ff = bits/numBits; bits %= numBits; break;
        default: fps = [F53Framerate invalidFramerateMarker];
	}
	return [F53Timecode timecodeWithFramerate:fps negative:NO hours:hh minutes:mm seconds:ss frames:ff bits:bits];
}

+ (F53Framerate *) framerateForCASMPTEType:(UInt32)smpteType
{
	switch ( smpteType )
    {
		case kSMPTETimeType2398:	 return [F53Framerate framerateWith23976fps];
		case kSMPTETimeType24:		 return [F53Framerate framerateWith24fps];
		case kSMPTETimeType25:		 return [F53Framerate framerateWith25fps];
		case kSMPTETimeType2997:	 return [F53Framerate framerateWith2997nondrop];
		case kSMPTETimeType2997Drop: return [F53Framerate framerateWith2997drop];
		case kSMPTETimeType30:		 return [F53Framerate framerateWith30nondrop];
		case kSMPTETimeType30Drop:	 return [F53Framerate framerateWith30drop];
		default:					 return [F53Framerate invalidFramerateMarker];
	}
}

+ (UInt32) CASMPTETypeForFramerate:(F53Framerate *)framerate
{
	switch ( framerate.framesPerSecond )
    {
		case 24: 
            if ( framerate.videoSpeed ) 
                return kSMPTETimeType2398;
            else
                return kSMPTETimeType24;
		case 25: 
            return kSMPTETimeType25;
		case 30: 
			if ( framerate.dropFrame )
				if ( framerate.videoSpeed )
                    return kSMPTETimeType2997Drop;
                else
                    return kSMPTETimeType30Drop;
			else
				if ( framerate.videoSpeed )
                    return kSMPTETimeType2997;
                else
                    return kSMPTETimeType30;
		default: return kSMPTETimeType2997;
	}
}


- (SMPTETime) SMPTETime
{
	SMPTETime result;
	result.mSubframeDivisor = 80;
	result.mFlags = kSMPTETimeValid;
	switch ( self.framerate.framesPerSecond )
    {
		case 30: result.mType = self.framerate.videoSpeed ? (self.framerate.dropFrame ? kSMPTETimeType2997Drop : kSMPTETimeType2997) : (self.framerate.dropFrame ? kSMPTETimeType30Drop : kSMPTETimeType30); break;
		case 25: result.mType = kSMPTETimeType25; break;	// CoreAudio has no constant for 24.975
		case 24: result.mType = self.framerate.videoSpeed ? kSMPTETimeType2398 : kSMPTETimeType24; break;
		default: result.mFlags = 0; break;                  // invalid timecode
	}
	result.mHours = self.hours;
	result.mMinutes = self.minutes;
	result.mSeconds = self.seconds;
	result.mFrames = self.frames;
	result.mSubframes = self.bits;
	return result;
}

@end
