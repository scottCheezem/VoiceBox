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


@interface AudioViewController ()
@property(nonatomic, retain)Superpowered *superPowered;
@property(nonatomic, retain)CADisplayLink *displayLink;
@property(nonatomic, retain)NSMutableArray *layers;

@end

@implementation AudioViewController

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
    _displayLink.frameInterval = 1;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)onDisplayLink {
    
    
//    Byte beanData[4] = { 0, 1, 2, 3 };
//    NSData *beanPayload = [NSData dataWithBytes:beanData length:sizeof(beanData)];
//    [self.lightControllerBean sendSerialData:beanPayload];
    
    [self.lightControllerBean sendSerialString:@"TEST"];
    
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


@end
