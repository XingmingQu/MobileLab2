//
//  SMUGraphHelper.h
//  AudioLab
//
//  Created by Eric Larson .
//  Copyright © 2013 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kGraphMaxSize 16000
#import <GLKit/GLKit.h>


enum PlotStyle {
    PlotStyleOverlaid,
    PlotStyleSeparated
};


@interface SMUGraphHelper : NSObject

-(SMUGraphHelper*)initWithController:(GLKViewController*) selfinput
            preferredFramesPerSecond:(int) framesPerSecond
                           numGraphs:(int) numArrays
                           plotStyle:(enum PlotStyle) plotStyleInput
                   maxPointsPerGraph:(int) maxGraphSize;


-(void)tearDownGL;
-(void) setFullScreenBounds;
-(void) setScreenBoundsTopHalf;
-(void) setScreenBoundsBottomHalf;
-(void) setBoundsWithTop:(float)inTop
                  bottom:(float)inBottom
                    left:(float)inLeft
                   right:(float)inRight;
-(void) update;
-(void) setGraphData:(float*)data
      withDataLength:(int)dataLength
       forGraphIndex:(int)arrayNum
   withNormalization:(float)normalization
        withZeroValue:(float)minValue;

-(void) setGraphData:(float*)data
      withDataLength:(int)dataLength
       forGraphIndex:(int)arrayNum;


-(void) draw;

@end
