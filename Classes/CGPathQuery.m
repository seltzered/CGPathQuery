//
//  CGPathQuery.m
//  CGPathQueryDemo
//
//  Created by Vivek Gani on 8/2/15.
//  Copyright (c) 2015 Vivek Gani. All rights reserved.
//

#import "CGPathQuery.h"
#import "CAAnimation+Blocks.h"
#import <QuartzCore/QuartzCore.h>
#import <AppKit/NSOpenGL.h>

@interface CGPathQuery ()
{
    NSOpenGLContext * oglContext;
    CARenderer * renderer;
    CALayer * backingLayer;
}

@property (strong, nonatomic) NSMutableArray * queryData;
@property (assign, nonatomic) PathCalculationStateEnum pathCalculationState;
@property (assign, nonatomic) CGFloat delta;
@property (assign, nonatomic) CGFloat zeroToOneCompletionStart;
@property (assign, nonatomic) CGFloat zeroToOneCompletionEnd;

@end

@implementation CGPathQuery

- (instancetype) init
{
    self = [super init];
    if(self == nil) return nil;
    
    self.pathCalculationState = PathCalculationInit;
    
    return self;
}

- (NSError *) calculatePointsAlongPath:(CGPathRef)path
      completionStart:(CGFloat)zeroToOneCompletionStart
                  completionEnd:(CGFloat)zeroToOneCompletionEnd
                  completionDelta:(CGFloat)delta

{
    //
    // Validation
    //
    NSString * errorDomain = [[NSString alloc] initWithFormat:@"%@", [self class]];

    if(self.pathCalculationState == PathCalculationProcessing)
    {
        NSLog(@"Can't perform new calculations while we're still processing - consider creating a new instance to do concurrent calculations");

        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return error;
    }
    if(zeroToOneCompletionStart < 0.0 || zeroToOneCompletionStart > 1.0 )
    {
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return error;
    }
    if(zeroToOneCompletionEnd < 0.0 || zeroToOneCompletionEnd > 1.0 )
    {
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return error;
    }
    if(zeroToOneCompletionStart > zeroToOneCompletionEnd)
    {
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return error;
    }

    //
    // Calculate points along path
    //
    [self prepareOpenGL];

    self.pathCalculationState = PathCalculationProcessing;
    self.zeroToOneCompletionStart = zeroToOneCompletionStart;
    self.zeroToOneCompletionEnd = zeroToOneCompletionEnd;
    self.delta = delta;
    
    NSUInteger capacity = ((NSUInteger) ((zeroToOneCompletionEnd - zeroToOneCompletionStart) / delta)) + 1;
    self.queryData = nil;
    self.queryData = [[NSMutableArray alloc] initWithCapacity:capacity];//initWithObjects:[NSValue valueWithPoint:NSMakePoint(0.0, 0.0)] count:capacity];
    for(NSUInteger i = 0; i < capacity; i++)
        [self.queryData setObject:[NSValue valueWithPoint:NSMakePoint(0.0, 0.0)] atIndexedSubscript:i];
    
    __block NSUInteger finishCount = 1;
    
    for(NSUInteger i = 0; i < capacity; i++)
    {
        __block CALayer* pointLayer;
        CAKeyframeAnimation *animation;

        CGFloat completionPosition = zeroToOneCompletionStart + (delta * i);
        pointLayer = [CALayer layer];
        pointLayer.position = NSMakePoint(0.0, 0.0);
        pointLayer.bounds = CGRectMake(0, 0, 1, 1);
        pointLayer.backgroundColor = CGColorCreateGenericRGB(1, 1, 0, 0);
        pointLayer.contents = [[CIImage alloc] init];
        [pointLayer setDrawsAsynchronously:YES];
        
        [backingLayer addSublayer:pointLayer];
        
        animation = [CAKeyframeAnimation animation];
        
        animation.keyPath = @"position";
        animation.timeOffset = completionPosition;
        animation.speed = 0.0;
        animation.duration = 1.000000000000001; //this needs to be set slightly greater than 1.0 as setting just 1.0 will yield the wrong point at the end when endPosition is 1.0.
        animation.path = path;
        [animation setRemovedOnCompletion:YES];
        
        [animation setCompletion:^(BOOL finished){
            if(pointLayer == nil)
                return;
            
            CGFloat x = ((CALayer *)pointLayer.presentationLayer).position.x;
            CGFloat y = ((CALayer *)pointLayer.presentationLayer).position.y;
            
            [self.queryData setObject:[NSValue valueWithPoint:NSMakePoint(x, y)] atIndexedSubscript:i];
            
            [pointLayer removeFromSuperlayer];
            pointLayer = nil;
            
//            NSLog(@"x: %f y: %f completePos = %f cnt = %ld finished: %d ", x, y, completionPosition, finishCount, finished ? 1: 0);

            finishCount++;
            if(finishCount >= capacity)
            {
                self.pathCalculationState = PathCalculationDone;
                [self teardownOpenGL];
            }
        }];
        
        [pointLayer addAnimation:animation forKey:[[NSNumber numberWithFloat:completionPosition] stringValue] ];
        [pointLayer addAnimation:animation forKey:[[NSNumber numberWithFloat:completionPosition] stringValue] ];//NOTE: addAnimation called twice because calling once sometimes doesn't trigger animationDidStop - calling twice will trigger two notifications but we'll ignore the second one. Variations such as calling twice only the first time have shown unreliable depending on the number of times animation is called.
    }
    
    return nil;
}


- (NSValue *) pointAlongPathAtCompletion:(CGFloat)zeroToOneCompletion
                       error:(NSError *)error
{
    NSString * errorDomain = [[NSString alloc] initWithFormat:@"%@", [self class]];

    if(self.pathCalculationState == PathCalculationInit)
    {
        NSLog(@"Path calculations haven't happened yet");
        
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return nil;
    }
    if(self.pathCalculationState == PathCalculationProcessing)
    {
        NSLog(@"Path calculations are still being processed");
        
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return nil;
    }
    if(zeroToOneCompletion < self.zeroToOneCompletionStart)
    {
        NSLog(@"completion value less than start value");

        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return nil;
    }
    if(zeroToOneCompletion > self.zeroToOneCompletionEnd)
    {
        NSLog(@"completion value greater than end value");
        
        NSError * error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return nil;
    }
    
    NSUInteger startIndex = (NSUInteger) ((zeroToOneCompletion - self.zeroToOneCompletionStart) / self.delta);
    
    NSUInteger endIndex = startIndex + 1;
    if(endIndex >= [self.queryData count])
    {
        //just return the final value.
        return self.queryData[startIndex];
    }
    
    NSPoint startIndexPointPosition = [self.queryData[startIndex] pointValue];
    NSPoint endIndexPointPosition = [self.queryData[endIndex] pointValue];

    CGFloat startIndexCalcPt = self.zeroToOneCompletionStart + (startIndex * self.delta);
    CGFloat startIndexBias = 1.0 - ((zeroToOneCompletion - startIndexCalcPt) / self.delta);
    
    CGFloat averagedX = (startIndexPointPosition.x * startIndexBias) + (endIndexPointPosition.x * (1.0 - startIndexBias));
    CGFloat averagedY = (startIndexPointPosition.y * startIndexBias) + (endIndexPointPosition.y * (1.0 - startIndexBias));
    
    return [NSValue valueWithPoint:NSMakePoint(averagedX, averagedY)];
}

- (void) prepareOpenGL
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 32,
        0
    };
    oglContext = [[NSOpenGLContext alloc] initWithFormat:[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] shareContext:nil];
    
    renderer = [CARenderer rendererWithCGLContext:[oglContext CGLContextObj] options:nil];
    
    [CATransaction begin];
    backingLayer = [CALayer layer];
    backingLayer.bounds = CGRectMake(0, 0, 1, 1);
    backingLayer.backgroundColor = CGColorCreateGenericRGB(1, 1, 0, 0);
    [backingLayer setDrawsAsynchronously:NO];
    
    renderer.layer = backingLayer;
    renderer.bounds = backingLayer.bounds;
    
    [CATransaction commit];
}


- (void) teardownOpenGL
{
    [backingLayer removeFromSuperlayer];
    backingLayer = nil;
    oglContext = nil;
    renderer = nil;
}

@end
