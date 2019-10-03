//
//  analyzerModel.m
//  AudioLab
//
//  Created by Xingming on 9/21/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "analyzerModel.h"
//because our BUFFER_SIZE=2048*4
// so fft buffer size is half of it
#define FFT_BUFFER_SIZE 2048*2

@implementation analyzerModel

#pragma mark Lazy Instantiation

//the slider in model B viewController will call this function
-(void)setFrequency:(int)inputFreq{
    self.outputFrequency = inputFreq;
}

//other class can use sharedInstance to access the analysis functions
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
    double frequency = self.outputFrequency;     //starting frequency
    __block float phase = 0.0;
    __block float samplingRate = self.audioManager.samplingRate;
    double phaseIncrement = 2*M_PI*frequency/samplingRate;
    double sineWaveRepeatMax = 2*M_PI;
    
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         for (int i=0; i < numFrames; ++i)
         {
             data[i] = sin(phase);
             phase += phaseIncrement;
             if (phase >= sineWaveRepeatMax) phase -= sineWaveRepeatMax;
         }
     }];
    
    [self.audioManager play];
    
}

-(void)stopAudio {
    [self.audioManager setOutputBlock:nil];
}

// return the first peak index(will use in model B) and get the two peak fequency
- (int)findTwoPeaksFrom:(float *)fftArray Withlenth:(int)arrLength withWindowSize:(int)windowSize returnFirstFeqAt:(int *)firstFeq returnSecondFeqAt:(int *)secondFeq{
    
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
        // but we also add peaks at least 50Hz apart so we add a constrain
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
    }
    // since our df =F_s/N =44100/8192 ~=5.38 HZ, we can multyply 5.38 to the index and get the frequency
    int first = 5.38 * firstPeakIndex;
    int second = 5.38 * secondPeakIndex;
    *firstFeq=first;
    *secondFeq=second;
    
    return firstPeakIndex;
}

//this function is just for analysis. Get a zoomed area around +=- range of the peak. So we can see how the points near peak move.
- (float *)getZoomedArr:(float *)fftArray WithRange:(int)range atIndex:(int)index returnZoomedArrLength:(int *)arrLength{
    int start,end;
    //check edge case
    start = index-range<0 ? 0: index-range;
    end = index+range>FFT_BUFFER_SIZE-1 ? FFT_BUFFER_SIZE-1: index+range;
    
    float *zoomedArr = malloc(sizeof(float)*((end-start)+1));
    //for edge case, sometimes the length of the arr is not range*2+1
    *arrLength=(end-start)+1;
    for(int i=start,j=0;i<end;i++,j++){
        zoomedArr[j]=fftArray[i];
    }
    return zoomedArr;
}

- (int)getMotionByZoomedArr:(float *)zoomedArr withArrLength:(int)arrLength{
    
    //for normalize, first we find max abs value
    double arrMax=fabsf(zoomedArr[0]) ;
    for(int i=1;i<arrLength;i++){
        if(fabsf(zoomedArr[i])>arrMax){
            arrMax=fabsf(zoomedArr[i]);
        }
    }
    //normalize the array element to [-1,1]
    for(int i=0;i<arrLength;i++){
        zoomedArr[i] = zoomedArr[i]/arrMax;
    }

    // after hours of experiments, we got the magic value = 0.8
    double right,left;
    right = zoomedArr[arrLength/2]-zoomedArr[arrLength-2] ;
    left = zoomedArr[arrLength/2]-zoomedArr[0];
    //    NSLog(@"left   : %f",zoomedArr[arrLength/2]-zoomedArr[0] );
//    NSLog(@"right  : %f",zoomedArr[arrLength/2]-zoomedArr[arrLength-2] );
    
    //here we define 0 =push 1=pull 2 =no motion
    if (right<0.8){
        return 0;
    }
    if(left<0.8)
        return 1;
    return 2;
}
@end
