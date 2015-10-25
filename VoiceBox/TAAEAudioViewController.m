//
//  TAAEAudioViewController.m
//  
//
//  Created by Scott Cheezem on 10/24/15.
//
//

#import "TAAEAudioViewController.h"
#import "TheAmazingAudioEngine.h"

#import "AEPlaythroughChannel.h"

#define BAR_MIN_VAL -20
#define BAR_MAX_VAL 0



@interface TAAEAudioViewController ()
@property(nonatomic, retain)AEAudioController *audioController;
@property(nonatomic, weak)NSTimer *levelsTimer;
@property (weak, nonatomic) IBOutlet UIProgressView *inputAveBar;
@property (weak, nonatomic) IBOutlet UIProgressView *inputPeakBar;
@property (weak, nonatomic) IBOutlet UISlider *inputGainSlider;


@end

@implementation TAAEAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    [self setupAduioController];
    self.inputGainSlider.value = self.audioController.inputGain;
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.levelsTimer invalidate];
    self.levelsTimer = nil;
}


-(void)setupAduioController{
    AudioStreamBasicDescription asbd = AEAudioStreamBasicDescriptionNonInterleavedFloatStereo;
    
    self.audioController = [[AEAudioController alloc]initWithAudioDescription:asbd inputEnabled:YES];
    self.audioController.preferredBufferDuration = 0.005;
    NSError *startAudioError = nil;
    [self.audioController start:&startAudioError];
    
    self.levelsTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(updateLevels:) userInfo:nil repeats:YES];
    
}


static inline float translate(float val, float min, float max) {
    if ( val < min ) val = min;
    if ( val > max ) val = max;
    return (val - min) / (max - min);
}


-(void)updateLevels:(NSTimer*)timer{
    
    Float32 inputAve, inputPeak;
    [self.audioController inputAveragePowerLevel:&inputAve peakHoldLevel:&inputPeak];
//    NSLog(@"inputAve:%f, inputPeak:%f", inputAve, inputPeak);
    
    self.inputAveBar.progress = translate(inputAve, BAR_MIN_VAL, BAR_MAX_VAL);
    self.inputPeakBar.progress = translate(inputPeak, BAR_MIN_VAL, BAR_MAX_VAL);
    
    //here is where we would send data to the bean...
    
}
- (IBAction)inputGainSliderValueChanged:(UISlider*)sender {
    self.audioController.inputGain = sender.value;
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
