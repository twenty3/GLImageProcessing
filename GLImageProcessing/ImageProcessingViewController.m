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

- (void)drawFrame;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation ImageProcessingViewController

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [self drawFrame];
}


#pragma mark - Draw

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
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"GrayscaleShader" ofType:@"fsh"];
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

    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

@end
