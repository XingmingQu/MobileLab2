//
//  ModelBViewController.m
//  AudioLab
//
//  Created by Xingming on 9/19/19.
//  Copyright © 2019 Eric Larson. All rights reserved.
//

#import "ModelBViewController.h"
#import "analyzerModel.h"
@interface ModelBViewController ()
@property (weak, nonatomic) IBOutlet UISlider *frequencyControlSlider;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (strong, nonatomic) analyzerModel* myAnalyzerModel;
@end

@implementation ModelBViewController

-(analyzerModel*)myAnalyzerModel{
    
    if(!_myAnalyzerModel)
        _myAnalyzerModel =[analyzerModel sharedInstance];
    
    return _myAnalyzerModel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.myAnalyzerModel stopAudio];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    self.frequencyLabel.text = [NSString stringWithFormat:@"%d kHz", (int)sender.value];
//    self.myAnalyzerModel.outputFrequency = (double)sender.value;
    [self.myAnalyzerModel setFrequency:(int)sender.value];
    [self.myAnalyzerModel playAudio];
//    NSLog(@"%d,",self.myAnalyzerModel.outputFrequency);
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
