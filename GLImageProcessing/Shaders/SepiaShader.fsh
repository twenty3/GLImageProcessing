//
//  SepiaShader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

precision mediump float;

varying vec2 interpolatedTextureCoordinate;
uniform sampler2D sourceTexture;


void main()
{
    vec3 coefficients = vec3(0.2125, 0.7154, 0.0721);
        // common rgb to gray weighting
    vec3 sepiaWeights = vec3(0.23, 0.11, 0.00);
        //boost the red a bit, the green a bit less and leave the blue

    vec4 source = texture2D(sourceTexture, interpolatedTextureCoordinate);
        // sample the original pixel    
    
    float l = dot(coefficients, source.rgb);
        // perceptual luminance of the rgb source
    
    source.rgb = vec3(l, l, l) + sepiaWeights;
        // weight the luminence by the sepia values
    
    gl_FragColor = source;
}
