//
//  TAAEAudioViewController.m
//  
//
//  Created by Scott Cheezem on 10/24/15.
//
//

#import "TAAEAudioViewController.h"
#import "TheAmazingAudioEngine.h"
#import "AENewTimePitchFilter.h"
#import "AEVarispeedFilter.h"
#import "AEPlaythroughChannel.h"

#import "BeanBrowserViewController.h"
#import <PTDBean.h>
#define BAR_MIN_VAL -20
#define BAR_MAX_VAL 0



@interface TAAEAudioViewController ()<PTDBeanDelegate>
@property(nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, strong) AEPlaythroughChannel *playthrough;
@property (nonatomic, strong) AENewTimePitchFilter *pitchFilter;

@property (weak, nonatomic) IBOutlet UISwitch *playThroughSwitch;
@property(nonatomic, weak)NSTimer *levelsTimer;
@property (weak, nonatomic) IBOutlet UIProgressView *inputAveBar;
@property (weak, nonatomic) IBOutlet UIProgressView *inputPeakBar;
@property (weak, nonatomic) IBOutlet UISlider *inputGainSlider;


@end

@implementation TAAEAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAduioController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.inputGainSlider.value = self.audioController.inputGain;
    self.playThroughSwitch.enabled = (self.playthrough == nil);
    self.levelsTimer = [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(updateLevels:) userInfo:nil repeats:YES];
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
    
    

}

-(void)setLightControllerBean:(PTDBean *)lightControllerBean{
    _lightControllerBean = lightControllerBean;
    _lightControllerBean.delegate = self;
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
    float translatedInputPeak = translate(inputPeak, BAR_MIN_VAL, BAR_MAX_VAL);
    
    self.inputAveBar.progress = translate(inputAve, BAR_MIN_VAL, BAR_MAX_VAL);
    self.inputPeakBar.progress = translatedInputPeak;
    
    
    float scaledInputPeak = translatedInputPeak * 255;
    NSNumber *beanFriendlyValues = [NSNumber numberWithFloat:scaledInputPeak];
    NSLog(@"sending %@", beanFriendlyValues.stringValue);

    [self.lightControllerBean sendSerialString:beanFriendlyValues.stringValue];
    
}
- (IBAction)inputGainSliderValueChanged:(UISlider*)sender {
    self.audioController.inputGain = sender.value;
}


- (IBAction)playthroughSwitchChanged:(UISwitch*)sender {
    if ( sender.isOn ) {
        self.playthrough = [[AEPlaythroughChannel alloc] initWithAudioController:_audioController];
        [_audioController addInputReceiver:_playthrough];
        [_audioController addChannels:@[_playthrough]];
    } else {
        [_audioController removeChannels:@[_playthrough]];
        [_audioController removeInputReceiver:_playthrough];
        self.playthrough = nil;
    }
}

-(IBAction)pitchSliderValueChanged:(UISlider*)sender{

    self.pitchFilter.pitch = sender.value ;
}

-(IBAction)pitchSwitchValueCHanged:(UISwitch*)sender{
    
    if(sender.isOn){
        self.pitchFilter = [[AENewTimePitchFilter alloc]init];
        self.pitchFilter.overlap = 12;//normally 8.0;
        [self.audioController addFilter:self.pitchFilter];
    }else{
        [self.audioController removeFilter:self.pitchFilter];
        self.pitchFilter = nil;
    }
}


-(void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data{
    NSString *dataString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(dataString);
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"beanBrowserSegue"]) {
        UINavigationController *navController = (UINavigationController*)segue.destinationViewController;
        BeanBrowserViewController *browserViewController = (BeanBrowserViewController*)navController.childViewControllers.firstObject;
        browserViewController.audioViewController = self;
    }
    
    
}

@end
