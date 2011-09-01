//
//  SaturationShader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

precision mediump float;

varying vec2 interpolatedTextureCoordinate;
uniform sampler2D sourceTexture;
uniform float amount;
    // the 'amount' uniform variable is set by the client before rendering

const vec3 coefficients = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    vec4 source = texture2D(sourceTexture, interpolatedTextureCoordinate);
        // sample the original pixel    

    vec3 target = vec3(dot(coefficients, source.rgb));
        // for brightness the target is black or zero intensity in each channel

    source.rgb = mix(target, source.rgb, amount);
        // using buil-in mix() function to do the interpolation. Probably optimized!
    
    gl_FragColor = source;
}
