//
//  GLImageProcessingAppDelegate.m
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

#import "GLImageProcessingAppDelegate.h"

#import "EAGLView.h"

#import "ImageProcessingViewController.h"

@implementation GLImageProcessingAppDelegate

@synthesize window = window_;
@synthesize viewController = viewController_;

#pragma mark - Lifecycle

- (void)dealloc
{
    [window_ release];
    [viewController_ release];
    [super dealloc];
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window.rootViewController = self.viewController;
    return YES;
}


@end
