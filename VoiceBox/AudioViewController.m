//
//  ViewController.m
//  VoiceBox
//
//  Created by Scott Cheezem on 10/14/15.
//  Copyright (c) 2015 Scott Cheezem. All rights reserved.
//

#import "AudioViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SuperPowered.h"
#import "BeanBrowserViewController.h"
#import <PTDBean.h>

@interface AudioViewController ()<PTDBeanDelegate>
@property(nonatomic, retain)Superpowered *superPowered;
@property(nonatomic, retain)CADisplayLink *displayLink;
@property(nonatomic, retain)NSMutableArray *layers;

@end

@implementation AudioViewController{
    NSTimer *beanTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.superPowered = [[Superpowered alloc]init];
    
    UIColor *color = [[UIColor colorWithRed:0 green:0.6 blue:0.8 alpha:1]init];
    _layers = [[NSMutableArray alloc]init];
    for (int i = 0 ; i <= 7 ; i++){
        CALayer *aLayer = [[CALayer alloc]init];
        aLayer.backgroundColor = color.CGColor;
        aLayer.frame = CGRectZero;
        [_layers addObject:aLayer];
        [self.view.layer addSublayer:aLayer];
    }
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink)];
    _displayLink.frameInterval = 2;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setLightControllerBean:(PTDBean *)lightControllerBean{
    _lightControllerBean = lightControllerBean;
    beanTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateBean) userInfo:nil repeats:YES];
    _lightControllerBean.delegate = self;
}

-(void)onDisplayLink {

    
    float frequencies[8] = { 55, 110, 220, 440, 880, 1760, 3520, 7040 };
    
    [_superPowered getFrequencies:frequencies];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
    
    
    CGFloat originY = self.view.frame.size.height - 20;
    CGFloat width = (self.view.frame.size.width - 47)/8;
    CGRect frame = CGRectMake(20, 0, width, 0);
    
    for (CALayer *aLayer in _layers){
        int index = [NSNumber numberWithUnsignedInteger:[_layers indexOfObject:aLayer]].intValue;
        frame.size.height = frequencies[index] * 4000;
        frame.origin.y = originY - frame.size.height;
        aLayer.frame = frame;
        frame.origin.x += width + 1;
    }
    
    [CATransaction commit];
    
    
}

-(void)updateBean{
    
    float frequencies[8] = { 55, 110, 220, 440, 880, 1760, 3520, 7040 };
    
    [_superPowered getFrequencies:frequencies];

    [self.lightControllerBean sendSerialString:@"TEST"]; //but really send the freqs or something else...
//    NSLog(@"%lu", sizeof(frequencies));
//    
////        Byte beanData[4] = { 0, 1, 2, 3 };
//        NSData *beanPayload = [NSData dataWithBytes:frequencies length:sizeof(frequencies)];
//        [self.lightControllerBean sendSerialData:beanPayload];
    
    
}



-(void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data{
    NSString *dataString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"beanBrowserSegue"]) {
        UINavigationController *navController = (UINavigationController*)segue.destinationViewController;
        BeanBrowserViewController *browserViewController = (BeanBrowserViewController*)navController.childViewControllers.firstObject;
        browserViewController.audioViewController = self;
    }
    
    
}


@end
