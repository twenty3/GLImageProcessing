//
//  Shader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

varying mediump vec2 interpolatedTextureCoordinate;
    // Vertex shader provides this value for each vertex. When we read it here, it will be interpolated (perspective correct) for the fragment we are coloring based on its location in respect each relevant vertex 

uniform sampler2D sourceTexture;
    // This uniform is of the special type sampler2D. The value of this type is the texture unit to sample from. The value should be provided by the client and should be the texture unit we have bound our source texture too in the GL state.

void main()
{
    // sample from the source texture with texture2D. Use the interpolated texture coordinate we get from the vertex shader. Simply output this value as the color of the fragment
    
    gl_FragColor = texture2D(sourceTexture, interpolatedTextureCoordinate);
}
