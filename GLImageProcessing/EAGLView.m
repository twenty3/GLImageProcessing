//
//  EAGLView.m
//  OpenGLES_iPhone
//
//  Created by mmalc Crawford on 11/18/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "EAGLView.h"

#import <QuartzCore/QuartzCore.h>


@interface EAGLView ()
{
    // The pixel dimensions of the CAEAGLLayer.
    GLint framebufferWidth;
    GLint framebufferHeight;

    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view.
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
}

- (void)createFramebuffer;
- (void)deleteFramebuffer;

@end

@implementation EAGLView

#pragma mark - Synthesize properties

@synthesize context = context_;

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
	if (self)
    {
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
    }
    
    return self;
}

- (void)dealloc
{
    [self deleteFramebuffer];    
    [context_ release];
    
    [super dealloc];
}

#pragma mark - UIView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews
{
    // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
    [self deleteFramebuffer];
}

#pragma mark - Properties

- (void)setContext:(EAGLContext *)newContext
{
    if (context_ != newContext)
    {
        [self deleteFramebuffer];
        [context_ release];
        context_ = [newContext retain];;
        
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - Framebuffer

- (void)createFramebuffer
{
    if (self.context && !defaultFramebuffer)
    {
        [EAGLContext setCurrentContext:self.context];
        
        // Create default framebuffer object.
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create color render buffer and allocate backing store.
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        
        if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)deleteFramebuffer
{
    if (self.context)
    {
        [EAGLContext setCurrentContext:self.context];
        
        if (defaultFramebuffer)
        {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer)
        {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
    }
}

- (void)setFramebuffer
{
    if (self.context)
    {
        [EAGLContext setCurrentContext:self.context];
        
        if (!defaultFramebuffer)
            [self createFramebuffer];
        
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        glViewport(0, 0, framebufferWidth, framebufferHeight);
    }
}

- (BOOL)presentFramebuffer
{
    BOOL success = FALSE;
    
    if (self.context)
    {
        [EAGLContext setCurrentContext:self.context];
        
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        success = [self.context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}


@end
