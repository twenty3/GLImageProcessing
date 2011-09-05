//
//  Shader.vsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

attribute vec4 position;
    // This attribute comes from the client application
    // represents the location of each vertex to render

attribute vec2 textureCoordinate;
    // This attribute comes from the client application
    // represents teh texture coordinates to use for this vertex

uniform mat4    mvpMatrix;
    // a tranformation matrix supplied by the client to go from model and view space to clip space

varying vec2 interpolatedTextureCoordinate;
    // This varible is interpolated for each fragment from the contributing vertices

void main()
{
    gl_Position = mvpMatrix * position;
    
    // make the texture coordinate attribute the client set for this vertex available to the fragment shader
    interpolatedTextureCoordinate = textureCoordinate;
}
