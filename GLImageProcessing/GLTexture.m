//
//  GLTexture.m
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/28/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

#import "GLTexture.h"

@interface GLTexture ()

@property   (nonatomic, assign, readwrite)   GLuint textureName;

@end

@implementation GLTexture

@synthesize  textureName = textureName_;


#pragma mark - Class methods

+ (GLTexture*) textureWithImage:(UIImage*)image
{
    return [[[self alloc] initWithImage:image] autorelease];
}


#pragma mark - Lifecycle

- (id)initWithImage:(UIImage*)image
{
    self = [super init];
    if (self)
    {
        GLsizei width       = image.size.width;
        GLsizei height      = image.size.height;
        
        GLubyte* textureData = (GLubyte*) calloc(width * height * 4, sizeof(GLubyte));
            // allocate memory for the bitmap context we will draw the image into
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            // We are going to force the source data to RGB space in the event it was some other color space
        
        CGContextRef textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4,
                                                            colorSpace, kCGImageAlphaPremultipliedLast);
            // We are going ot use pre-multiplied data. Our later processing may need to account for this when manipulating RGB values
        
        CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)width), image.CGImage);
            // Draw the image into the bitmap context
        
        glGenTextures(1, &textureName_);
        glBindTexture(GL_TEXTURE_2D, self.textureName);
            // Get a texture name and bind it as the current 2D texture in the GL state
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);   
            // copy the bitmap data backing the CGBitmapContext over to GL into the texture we have bound
        
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR); 
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
            // depending on your application, you may want different scaling filters for the source texture
            // for instance you may want scaling to produce a pixelated zoom instead of smoothing
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            // GL_CLAMP_TO_EDGE means that samples beyond the texture bounds will be replicated edge pixels
            // this mode is required to use textures that are not powers for two in size. 
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(textureContext);
        free(textureData);      
            // glTextImge2D has copied the pixel data over to the GL state, so we can release it safely
    }
    
    return self;
}

- (void)dealloc
{
    glDeleteTextures(1, &textureName_);
    [super dealloc];
}

#pragma mark - Binding

- (void) bindToTextureUnit:(GLenum)textureUnit
{
    glActiveTexture(textureUnit);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
        // set the active texture unit and bind this texture to it
}


@end
