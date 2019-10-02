//
//  ModelBViewController.m
//  AudioLab
//
//  Created by Xingming on 9/19/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "ModelBViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "FFTHelper.h"
#import "analyzerModel.h"

#define BUFFER_SIZE 2048*4

@interface ModelBViewController ()

@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;

@property (weak, nonatomic) IBOutlet UISlider *frequencyControlSlider;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (strong, nonatomic) analyzerModel* myAnalyzerModel;
@end

@implementation ModelBViewController

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}
-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}


-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(analyzerModel*)myAnalyzerModel{
    
    if(!_myAnalyzerModel)
        _myAnalyzerModel =[analyzerModel sharedInstance];
    
    return _myAnalyzerModel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    __block ModelBViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];

}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    // if we leave this page we stop the audio
    [self.myAnalyzerModel stopAudio];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d Hz", (int)sender.value];
//    self.myAnalyzerModel.outputFrequency = (double)sender.value;
    [self.myAnalyzerModel setFrequency:(int)sender.value];
    [self.myAnalyzerModel playAudio];
//    NSLog(@"%d,",self.myAnalyzerModel.outputFrequency);
    
}


@end
