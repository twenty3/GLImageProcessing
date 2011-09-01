//
//  ImageProcessingViewController.h
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ImageProcessingViewController : UIViewController

@property(nonatomic, retain) IBOutlet UISlider* slider;

@end
