//
//  SuperPowered.mm
//  
//
//  Created by Scott Cheezem on 10/14/15.
//
//
#import "SuperPowered.h"

#import "SuperpoweredIOSAudioOutput.h"
#include "SuperpoweredBandpassFilterbank.h"
#include "SuperpoweredSimple.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <pthread.h>

#define NUM_BANDS 8

@implementation Superpowered {
    SuperpoweredIOSAudioOutput *audioIO;
    SuperpoweredBandpassFilterbank *filters;
    float bands[NUM_BANDS];
    pthread_mutex_t mutex;
    unsigned int samplerate, samplesProcessedForOneDisplayFrame;
}

- (id)init {
    self = [super init];
    if (!self) return nil;
    samplerate = 44100;
    samplesProcessedForOneDisplayFrame = 0;
    memset(bands, 0, NUM_BANDS * sizeof(float));
    
    // We use a mutex to prevent simultaneous reading/writing of bands.
    pthread_mutex_init(&mutex, NULL);
    
    float frequencies[NUM_BANDS] = { 55, 110, 220, 440, 880, 1760, 3520, 7040 };
    float widths[NUM_BANDS] = { 1, 1, 1, 1, 1, 1, 1, 1 };
    filters = new SuperpoweredBandpassFilterbank(NUM_BANDS, frequencies, widths, samplerate);
    
    audioIO = [[SuperpoweredIOSAudioOutput alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredMinimumSamplerate:44100 audioSessionCategory:AVAudioSessionCategoryPlayAndRecord multiChannels:2 fixReceiver:2];

    

//setCategory:AVAudioSessionCategoryPlayAndRecord
//withOptions:AVAudioSessionCategoryOptionAllowBluetooth
//error:&error];

    NSError *error = nil;
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&error];

    NSArray *inputs = [[AVAudioSession sharedInstance]availableInputs];

    NSError *audioError = nil;

    audioIO.inputEnabled = true;
    
    NSArray* bluetoothinputRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    AVAudioSessionPortDescription* _bluetoothPort = [self audioDeviceFromTypes:bluetoothinputRoutes];
    BOOL changeResult = [[AVAudioSession sharedInstance] setPreferredInput:_bluetoothPort error:&audioError];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
//    NSArray *outputs = [[AVAudioSession sharedInstance]outputDataSources];
    
    
//   BOOL changed =  [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&audioError];
    [audioIO start];
    
    return self;
}

- (void)dealloc {
    delete filters;
    pthread_mutex_destroy(&mutex);
    audioIO = nil;
}

- (void)interruptionEnded {}

- (bool)audioProcessingCallback:(float **)buffers inputChannels:(unsigned int)inputChannels outputChannels:(unsigned int)outputChannels numberOfSamples:(unsigned int)numberOfSamples samplerate:(unsigned int)currentsamplerate hostTime:(UInt64)hostTime {
    if (samplerate != currentsamplerate) {
        samplerate = currentsamplerate;
        filters->setSamplerate(samplerate);
    };
    
    // Mix the non-interleaved input to interleaved.
    float interleaved[numberOfSamples * 2 + 16];
    SuperpoweredInterleave(buffers[0], buffers[1], interleaved, numberOfSamples);
    
    // Detect frequency magnitudes.
    float peak, sum;
    pthread_mutex_lock(&mutex);
    samplesProcessedForOneDisplayFrame += numberOfSamples;
    filters->process(interleaved, bands, &peak, &sum, numberOfSamples);
    pthread_mutex_unlock(&mutex);
    
    return false;
}

/*
 It's important to understand that the audio processing callback and the screen update (getFrequencies) are never in sync.
 More than 1 audio processing turns can happen between two consecutive screen updates.
 */

- (void)getFrequencies:(float *)freqs {
    pthread_mutex_lock(&mutex);
    if (samplesProcessedForOneDisplayFrame > 0) {
        for (int n = 0; n < NUM_BANDS; n++) freqs[n] = bands[n] / float(samplesProcessedForOneDisplayFrame);
            memset(bands, 0, NUM_BANDS * sizeof(float));
            samplesProcessedForOneDisplayFrame = 0;
            } else memset(freqs, 0, NUM_BANDS * sizeof(float));
                pthread_mutex_unlock(&mutex);
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

@end
