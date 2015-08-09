//
//  AppDelegate.m
//  CGPathQueryDemo
//
//  Created by Vivek Gani on 8/2/15.
//  Copyright (c) 2015 Vivek Gani. All rights reserved.
//

#import "AppDelegate.h"
#import "CGPathQuery.h"

@interface AppDelegate ()

@property (nonatomic, strong) CGPathQuery * pathQuery;
@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *calculatePositionCompletionValue;
@property (weak) IBOutlet NSButton *calculatePositionButton;

@property (weak) IBOutlet NSTextField *calculatedPositionX;
@property (weak) IBOutlet NSTextField *calculatedPositionY;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    //create a path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 0.0, 150.0);
    CGPathAddCurveToPoint(path, nil,
                          75.0, 0.0, 225.0, 300.0, 300.0, 150.0);
    
    self.pathQuery = [[CGPathQuery alloc] init];
    NSError * pointErr = [self.pathQuery calculatePointsAlongPath:path
                                                  completionStart:0.0
                                                    completionEnd:1.0
                                                  completionDelta:0.01];
}


- (IBAction)calculatePositionButtonClicked:(id)sender {
    
    NSError * error;
    NSValue * pointVal = [self.pathQuery pointAlongPathAtCompletion:[self.calculatePositionCompletionValue floatValue] error:error];
    
    [self.calculatedPositionX setFloatValue:[pointVal pointValue].x];
    [self.calculatedPositionY setFloatValue:[pointVal pointValue].y];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
