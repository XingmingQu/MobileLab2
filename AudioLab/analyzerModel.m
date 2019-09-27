//
//  analyzerModel.m
//  AudioLab
//
//  Created by Xingming on 9/21/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "analyzerModel.h"


@implementation analyzerModel

#pragma mark Lazy Instantiation

-(void)setFrequency:(int)inputFreq{
    self.outputFrequency = inputFreq;
}


+(analyzerModel*)sharedInstance{
    static analyzerModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[analyzerModel alloc] init];
    });
    
    return _sharedInstance;
}

-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
        NSLog(@"Finish init Novocaine audioManager");
    }
    return _audioManager;
}

-(void)playAudio {

    double frequency = self.outputFrequency * 1000;     //starting frequency
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    
    double phaseIncrement = 2*M_PI*frequency/samplingRate;
    double sineWaveRepeatMax = 2*M_PI;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         for (int i=0; i < numFrames; ++i)
         {
             data[i] = sin(phase);
//             NSLog(@"%.f",sin(phase));
             phase += phaseIncrement;
             if (phase >= sineWaveRepeatMax) phase -= sineWaveRepeatMax;
         }
     }];
    
    [self.audioManager play];
    
}

-(void)stopAudio {
    [self.audioManager setOutputBlock:nil];
}


- (void)findTwoPeaksFrom:(float *)fftArray Withlenth:(int)arrLength withWindowSize:(int)windowSize returnFirstFeqAt:(int *)firstFeq returnSecondFeqAt:(int *)secondFeq{
    
    // using https://developer.apple.com/documentation/accelerate/1450505-vdsp_vswmax?language=objc
    //vDSP_vswmax
    //Array must contain N + WindowLength - 1 element
    // Therefore, numOfWindowPosition = arrLength - windowSize + 1
    int numOfWindowPosition = arrLength - windowSize + 1 ;
    float *maxValueOfEachWindow = malloc(sizeof(float)*numOfWindowPosition);
    
    vDSP_vswmax(fftArray, 1, maxValueOfEachWindow, 1, numOfWindowPosition, windowSize);
    
    //So we have maxValueOfEachWindow. What we need to do next is to find all the peaks' indexes.
    // the way to find peak index is to traverse the fftArray
    // if the fftArray[i] == the maxValueOfEachWindow[i], this i is a peak index
    NSMutableArray *peaksIndex = [[NSMutableArray alloc] init];
    int current=-10000;
    for (int i = 0; i < numOfWindowPosition; i++) {
        // but we also add peaks at least 50Hz apart
        if (i-current>=windowSize && maxValueOfEachWindow[i] == fftArray[i] ) {
            [peaksIndex addObject:[NSNumber numberWithInteger:i]];
            current=i;
        }
    }
    
    // Next we can just find the first two largest peak by traversing peaksIndex
    int firstPeakIndex=[peaksIndex[0] intValue], secondPeakIndex=[peaksIndex[1] intValue];
    
    for(int i=2;i<peaksIndex.count;i++){
        int currentPeakIndex=[peaksIndex[i] intValue];
        if (fftArray[currentPeakIndex] > fftArray[firstPeakIndex]){
            secondPeakIndex=firstPeakIndex;
            firstPeakIndex=currentPeakIndex;
        }else if(fftArray[currentPeakIndex] > fftArray[secondPeakIndex] ){
            
            secondPeakIndex=currentPeakIndex;
        }
//        NSLog(@"%d",(secondPeakIndex-firstPeakIndex));
    }
    
    

    
    // since our df =F_s/N =44100/8192 ~=5.38 HZ
    
    int first = 5.38 * firstPeakIndex;
    int second = 5.38 * secondPeakIndex;
//    NSLog(@"%d",first);
//    NSLog(@"%d",second);
    *firstFeq=first;
    *secondFeq=second;
    
//    for(int i=0;i<10;i++){
//        NSLog(@"%f",maxValueOfEachWindow[i]);
//    }


}


@end
