//
//  GLTexture.h
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/28/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface GLTexture : NSObject

@property   (nonatomic, assign, readonly)   GLuint textureName;
    // returns the GL name assigned to this texture

+ (GLTexture*) textureWithImage:(UIImage*)image;

- (void) bindToTextureUnit:(GLenum)textureUnit;
    // Bind this texture to the specified textureUnit;

@end
