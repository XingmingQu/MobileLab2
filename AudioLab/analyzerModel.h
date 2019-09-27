//
//  analyzerModel.h
//  AudioLab
//
//  Created by Xingming on 9/21/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Novocaine.h"
NS_ASSUME_NONNULL_BEGIN

@interface analyzerModel : NSObject
@property (strong, nonatomic) Novocaine *audioManager;
+(analyzerModel*) sharedInstance;
@property (nonatomic) int outputFrequency;
-(void)setFrequency:(int)inputFreq;
-(void)playAudio;
-(void)stopAudio;
//-(NSArray *)findTwoPeaks：(int)windowSize ：(int)arrLength;
-(void)findTwoPeaksFrom:(float *)fftArray Withlenth:(int)arrLength withWindowSize:(int)windowSize returnFirstFeqAt:(int*)firstFeq returnSecondFeqAt:(int*)secondFeq;


@end

NS_ASSUME_NONNULL_END
