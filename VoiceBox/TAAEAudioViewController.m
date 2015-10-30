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
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BeanBrowserViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <PTDBean.h>
#define BAR_MIN_VAL -20
#define BAR_MAX_VAL 0

//static const int kAudioRouteChanged;

@interface TAAEAudioViewController ()<PTDBeanDelegate>
@property(nonatomic, retain) AEAudioController *audioController;
@property (nonatomic, strong) AEPlaythroughChannel *playthrough;
@property (nonatomic, strong) AENewTimePitchFilter *pitchFilter;

@property (weak, nonatomic) IBOutlet UISwitch *playThroughSwitch;
@property(nonatomic, weak)NSTimer *levelsTimer;
@property (nonatomic, weak)NSTimer *beanTimer;
@property (weak, nonatomic) IBOutlet UIProgressView *inputAveBar;
@property (weak, nonatomic) IBOutlet UIProgressView *inputPeakBar;
@property (weak, nonatomic) IBOutlet UISlider *inputGainSlider;
@property (weak, nonatomic) IBOutlet MPVolumeView *volumeView;
@property (weak, nonatomic) IBOutlet UIView *colorDisplayView;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;


@end

@implementation TAAEAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAduioController];
    self.volumeView.showsVolumeSlider = YES;
    self.volumeView.showsRouteButton = YES;
    [self updateColorDisplayView];
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
    [self.beanTimer invalidate];
    self.beanTimer = nil;
}


-(void)setupAduioController{
    AudioStreamBasicDescription asbd = AEAudioStreamBasicDescriptionNonInterleavedFloatStereo;
    
    self.audioController = [[AEAudioController alloc]initWithAudioDescription:asbd inputEnabled:YES];
    self.audioController.preferredBufferDuration = 0.005;
    
    NSError *audioError = nil;
    
    
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
//    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&audioError];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionDefaultToSpeaker
                   error:&audioError];

    
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&audioError];
    
    [session setPreferredInput:[self bluetoothAudioDevice] error:&audioError]; 
    
    
//    BOOL success;
//    NSError* error;
    
//    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    
//    success = [session setActive:YES error:&error];
    
  
    
    
//    else
//    {
//        UInt32 audioRouteOverride = kAudioSessionOutputRoute_Headphones;
//        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
//
//    }
    
    [self.audioController start:&audioError];
    

}


- (AVAudioSessionPortDescription*)bluetoothAudioDevice
{
    NSArray* bluetoothRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    return [self audioDeviceFromTypes:bluetoothRoutes];
}

- (AVAudioSessionPortDescription*)builtinAudioDevice
{
    NSArray* builtinRoutes = @[AVAudioSessionPortBuiltInMic];
    return [self audioDeviceFromTypes:builtinRoutes];
}

- (AVAudioSessionPortDescription*)speakerAudioDevice
{
    NSArray* builtinRoutes = @[AVAudioSessionPortBuiltInSpeaker];
    return [self audioDeviceFromTypes:builtinRoutes];
}

- (AVAudioSessionPortDescription*)audioDeviceFromTypes:(NSArray*)types
{
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if ([types containsObject:route.portType])
        {
            return route;
        }
    }
    return nil;
}

- (BOOL)switchBluetooth:(BOOL)onOrOff
{
    NSError* audioError = nil;
    BOOL changeResult = NO;
    if (onOrOff == YES)
    {
        AVAudioSessionPortDescription* _bluetoothPort = [self bluetoothAudioDevice];
        changeResult = [[AVAudioSession sharedInstance] setPreferredInput:_bluetoothPort
                                                                    error:&audioError];
    }
    else
    {
        AVAudioSessionPortDescription* builtinPort = [self builtinAudioDevice];
        changeResult = [[AVAudioSession sharedInstance] setPreferredInput:builtinPort
                                                                    error:&audioError];
    }
    return changeResult;
}


-(void)setLightControllerBean:(PTDBean *)lightControllerBean{
    _lightControllerBean = lightControllerBean;
    _lightControllerBean.delegate = self;
//    self.beanTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateBean) userInfo:nil repeats:YES];
}

//scale an input to a 0 to 1 value between a min an max value
static inline float translate(float val, float min, float max) {
    if ( val < min ) val = min;
    if ( val > max ) val = max;
    return (val - min) / (max - min);
}

//updated the local UI
-(void)updateLevels:(NSTimer*)timer{
    
    Float32 inputAve, inputPeak;
    [self.audioController inputAveragePowerLevel:&inputAve peakHoldLevel:&inputPeak];
//    NSLog(@"inputAve:%f, inputPeak:%f", inputAve, inputPeak);
    float translatedInputPeak = translate(inputPeak, BAR_MIN_VAL, BAR_MAX_VAL);
    
    self.inputAveBar.progress = translate(inputAve, BAR_MIN_VAL, BAR_MAX_VAL);
    self.inputPeakBar.progress = translatedInputPeak;
    
    if(self.lightControllerBean != nil){
        [self updateBean:inputAve :inputPeak];
    }
    
}

-(void)updateBean:(Float32)inputAve :(Float32)inputPeak{
    
//    Float32 inputAve, inputPeak;
    [self.audioController inputAveragePowerLevel:&inputAve peakHoldLevel:&inputPeak];
    //    NSLog(@"inputAve:%f, inputPeak:%f", inputAve, inputPeak);
    float translatedInputPeak = translate(inputPeak, BAR_MIN_VAL, BAR_MAX_VAL);
    
    CGFloat scaledInputPeak = translatedInputPeak * 255;
    
    Byte colorData[3];
    colorData[0] = scaledInputPeak*self.redSlider.value;
    colorData[1] = scaledInputPeak*self.greenSlider.value;
    colorData[2] = scaledInputPeak*self.blueSlider.value;
    
    NSData *beanData = [NSData dataWithBytes:colorData length:sizeof(colorData)];
    
    [self.lightControllerBean setScratchBank:1 data:beanData];
    
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
        self.pitchFilter.overlap = 10;//normally 8.0;
        [self.audioController addFilter:self.pitchFilter];
    }else{
        [self.audioController removeFilter:self.pitchFilter];
        self.pitchFilter = nil;
    }
}


-(void)updateColorDisplayView{
    self.colorDisplayView.backgroundColor = [UIColor colorWithRed:self.redSlider.value green:self.greenSlider.value blue:self.blueSlider.value alpha:1.0f];
}

- (IBAction)redSliderChanged:(id)sender {
    [self updateColorDisplayView];
}
- (IBAction)greenSliderChanged:(id)sender {
    [self updateColorDisplayView];
    
}
- (IBAction)blueSliderChanged:(id)sender {
    [self updateColorDisplayView];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"beanBrowserSegue"]) {
        UINavigationController *navController = (UINavigationController*)segue.destinationViewController;
        BeanBrowserViewController *browserViewController = (BeanBrowserViewController*)navController.childViewControllers.firstObject;
        browserViewController.audioViewController = self;
    }
    
    
}

@end
