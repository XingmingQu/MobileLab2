//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"
#import "analyzerModel.h"

#define BUFFER_SIZE 2048*4

@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (weak, nonatomic) IBOutlet UISwitch *lockInSwitch;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) analyzerModel *myAnalyzerModel;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *motionLabel;
@property (weak, nonatomic) IBOutlet UISlider *frequencyControlSlider;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;

@end



@implementation ViewController

#pragma mark Lazy Instantiation
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

- (analyzerModel *)myAnalyzerModel{
    if(!_myAnalyzerModel){
        _myAnalyzerModel = [analyzerModel sharedInstance];
    }
    return _myAnalyzerModel;
}



-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:3
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [self.graphHelper setFullScreenBounds];
    
    __block ViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    if (self.lockInSwitch.isOn == false){
        // get audio stream data
        float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
        float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
        
        
        [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
        
        //send off for graphing
        [self.graphHelper setGraphData:arrayData
                        withDataLength:BUFFER_SIZE
                         forGraphIndex:0];
        
        // take forward FFT
        [self.fftHelper performForwardFFTWithData:arrayData
                       andCopydBMagnitudeToBuffer:fftMagnitude];
        
        // graph the FFT Data
        [self.graphHelper setGraphData:fftMagnitude
                        withDataLength:BUFFER_SIZE/2
                         forGraphIndex:1
                     withNormalization:64.0
                         withZeroValue:-60];
        
        [self.graphHelper update]; // update the graph
        
        
        //Start peak finding..................
        //our df =F_s/N =44100/8192 ~=5.38 HZ
        // requirementt = Is able to distinguish tones at least 50Hz apart So our window size ~=10
        int windowSize=10;
        int firstFeq=0;
        int secondFeq=0;
        int firstPeakIndex;
        //Passing by reference
        firstPeakIndex=[self.myAnalyzerModel findTwoPeaksFrom:fftMagnitude Withlenth:BUFFER_SIZE/2 withWindowSize:windowSize returnFirstFeqAt:&firstFeq returnSecondFeqAt:&secondFeq];
        
        
        self.firstLabel.text = [NSString stringWithFormat:@"%d Hz", firstFeq];
        self.secondLabel.text = [NSString stringWithFormat:@"%d Hz", secondFeq];
        
        //auto lock
//        NSLog(@"%f",fftMagnitude[firstPeakIndex]);
        if(fftMagnitude[firstPeakIndex]<-3.5){
//            NSLog(@"%@",@"Lock");
            self.lockInSwitch.on = true;
        }
        
        
        //plot a zoomedArr just for model B
        float * zoomedArr;
        int range=5;
        int zoomedArrLen;
        zoomedArr=[self.myAnalyzerModel getZoomedArr:fftMagnitude WithRange:range atIndex:firstPeakIndex returnZoomedArrLength:&zoomedArrLen];
        
        //dynamically change the zoomedArrLen
        [self.graphHelper setGraphData:zoomedArr
                        withDataLength:zoomedArrLen
                         forGraphIndex:2
                     withNormalization:16.0
                         withZeroValue:-60];
        
        int result = [self.myAnalyzerModel getMotionByZoomedArr:zoomedArr withArrLength:zoomedArrLen];
//        NSLog(@"%d",result);
        if (result==0)
            self.motionLabel.text=[NSString stringWithFormat:@"Push"];
        else if (result ==1)
            self.motionLabel.text=[NSString stringWithFormat:@"Pull"];
        else
            self.motionLabel.text=[NSString stringWithFormat:@"No Motion"];
        
        free(arrayData);
        free(fftMagnitude);
    }
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    self.frequencyLabel.text = [NSString stringWithFormat:@"Output audio frequency: %d Hz", (int)sender.value];
    //    self.myAnalyzerModel.outputFrequency = (double)sender.value;
    [self.myAnalyzerModel setFrequency:(int)sender.value];
    [self.myAnalyzerModel playAudio];
    //    NSLog(@"%d,",self.myAnalyzerModel.outputFrequency);
    
}
- (IBAction)stopPlayButton:(UIButton *)sender {
    [self.myAnalyzerModel stopAudio];
}


@end
