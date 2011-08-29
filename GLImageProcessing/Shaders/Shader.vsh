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

varying vec2 interpolatedTextureCoordinate;
    // This varible is interpolated for each fragment from the contributing vertices

void main()
{
    // gl_Position is a special built-in varible. We output the computed vertex for each input vertex to this variable.
    // Normally there would be some tranfrom of the model vertices and the view (camera) followed by a transform into the clipping space that occurs here
    // For image processing tasks we place our texture on a flat square model and that is oriented parallel to the viewing surface and sized to occupy the entire viewport, so there are no required transforms here
    gl_Position = position;
    
    // make the color attribute the client set for this vertex available to the fragment shader
    interpolatedTextureCoordinate = textureCoordinate;
}
