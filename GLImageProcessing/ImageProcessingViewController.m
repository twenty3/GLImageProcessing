//
//  ImageProcessingViewController.m
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ImageProcessingViewController.h"
#import "EAGLView.h"
#import "GLTexture.h"

#pragma mark Enumerations

// Attributes
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE_COORDINATES,
    NUM_ATTRIBUTES
};

// Uniforms
enum {
    UNIFORM_SOURCE_TEXTURE,
    UNIFORM_AMOUNT_SCALAR,
    NUM_UNIFORMS
};

#pragma mark - Statics

static GLint uniforms[NUM_UNIFORMS];

#pragma mark -

@interface ImageProcessingViewController ()
{
    GLuint program;
}

@property (nonatomic, retain) EAGLContext* context;
@property (nonatomic, retain) GLTexture* sourceImage;

- (CGContextRef) newBitmapContextForSize:(CGSize)size;
- (UIImage*)imageFromEAGLLayer;
- (void)drawFrame;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (IBAction)sliderValueChanged:(id)sender;

@end

@implementation ImageProcessingViewController

@synthesize slider = slider_;
@synthesize context = context_;
@synthesize sourceImage = sourceImage_;

#pragma mark - Lifecycle

- (void)dealloc
{
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }
    
    // Tear down context.
    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];
    
    [context_ release];
    [sourceImage_ release];
    [slider_ release];
    
    [super dealloc];
}


#pragma mark - UINibLoading

- (void)awakeFromNib
{
    EAGLContext* context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    
    if (!context)
        NSLog(@"Failed to create ES 2.0 context");
    else if (![EAGLContext setCurrentContext:context])
        NSLog(@"Failed to set ES context current");
    
	self.context = context;
	
    [(EAGLView *)self.view setContext:self.context];
    [(EAGLView *)self.view setFramebuffer];
    
    if ([self.context API] == kEAGLRenderingAPIOpenGLES2)
        [self loadShaders];
    
    self.sourceImage = [GLTexture textureWithImage:[UIImage imageNamed:@"source_image.jpg"]];
    
    UITapGestureRecognizer* tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)] autorelease];
    [self.view addGestureRecognizer:tapRecognizer];
}


#pragma mark - UIViewController

- (void)viewDidUnload
{
	[super viewDidUnload];
	
    if (program)
    {
        glDeleteProgram(program);
        program = 0;
    }

    // Tear down context.
    if ([EAGLContext currentContext] == self.context)
        [EAGLContext setCurrentContext:nil];

	self.context = nil;	
    self.slider = nil;
    self.sourceImage = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self drawFrame];
}

#pragma mark - Actions


- (IBAction)sliderValueChanged:(id)sender
{
    [self drawFrame];
}

- (void)viewTapped:(id)sender
{
    UIImage* image = [self imageFromEAGLLayer];
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}


#pragma mark - Bitmaps

- (CGContextRef) newBitmapContextForSize:(CGSize)size
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo	bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
	int				rowByteWidth = size.width * 4;
	
	CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, rowByteWidth, colorSpace, bitmapInfo);
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

#pragma mark - Draw

- (UIImage*)imageFromEAGLLayer
{
    // grab the pixels from the framebuffer associated with our view's EAGLLayer and create a UIImage from the data.
    // The assumption made here is that rendering to the layer has already occured from a previous call to drawFrame:
    
    // Create a Core Graphics bitmap contenxt for which we provide the storage.
    
    GLsizei width = self.view.layer.bounds.size.width * self.view.contentScaleFactor;
    GLsizei height = self.view.layer.bounds.size.height * self.view.contentScaleFactor;    

    CGContextRef context = [self newBitmapContextForSize:(CGSize){width, height}];
	CGContextClearRect(context, (CGRect){0.0, 0.0, width, height});    
    void* pixelData = CGBitmapContextGetData(context);
    
    //Then we will use glReadPixels to copy the rendered image from the GL server storage (GPU) over to our newly allocated bitmap storage.    
    [(EAGLView *)self.view setFramebuffer];
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixelData);

    //Finally we'll create an image from the bitmap context with the dupilcated pixels

	CGImageRef contextImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    // TO DO: THE IMAGE IS UPSIDE DOWN!
        
    UIImage* image = [[[UIImage alloc] initWithCGImage:contextImage] autorelease];
    CGImageRelease(contextImage);
    
    return image;
}


- (void)drawFrame
{
    // This makes the context and framebuffer associated with our view current. GL State and drawing commands will be targeted to that context and render in that framebuffer
    [(EAGLView *)self.view setFramebuffer];
    
    // Here we declare a set of vertices that define a square that is paralell to the viewing plane.
    // These are effectively normalized device viewing space coordinates because we are not manipulating the modelview or projection transformations from their defaults and we have set up the viewport to match the size of our view
    static const GLfloat squareVertices[] =
    {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    // Here we declare an texture coordinates that map the source texture to the quad defined above. We simply place each corner of the source image on a corner of the quad.
    // Note that since our texture was from a CGImage, it is 'upside' down from what we would expect. These texture coordinates map the top of the image to the bottom of the quad and the bottom of the image to the top of the quad defined above.  
    static const GLfloat textureCoordinates[] =
    {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Use shader program.
    glUseProgram(program);
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_TEXTURE_COORDINATES, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glEnableVertexAttribArray(ATTRIB_TEXTURE_COORDINATES);
    
    // Bind the source texture to a texture unit and set the source sampler for the shader to that texture unit
    [self.sourceImage bindToTextureUnit:GL_TEXTURE0];
    glUniform1i(uniforms[UNIFORM_SOURCE_TEXTURE], 0);
    
    // Set the amount
    glUniform1f(uniforms[UNIFORM_AMOUNT_SCALAR], self.slider.value);
    
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
    if (![self validateProgram:program])
    {
        NSLog(@"Failed to validate program: %d", program);
        return;
    }
#endif
    
    // This causes GL to draw our scene with the current state- including the vertices and texture coordinate attributes we have supplied to the state above. The drawing is raterized into the current framebuffer
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // This casues the OS to display the rasterized scene 
    [(EAGLView *)self.view presentFramebuffer];
}

#pragma mark - Shaders

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"VignetteShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_TEXTURE_COORDINATES, "textureCoordinate");
    
    // Link program.
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader)
        {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program)
        {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Get Uniform locations from the linked programs
    uniforms[UNIFORM_SOURCE_TEXTURE] = glGetUniformLocation(program, "sourceTexture");
    uniforms[UNIFORM_AMOUNT_SCALAR] =  glGetUniformLocation(program, "amount");

    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

@end
