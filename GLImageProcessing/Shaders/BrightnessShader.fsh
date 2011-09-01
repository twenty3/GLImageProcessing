//
//  BrightnessShader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

precision mediump float;

varying vec2 interpolatedTextureCoordinate;
uniform sampler2D sourceTexture;
uniform float amount;
    // the 'amount' uniform variable is set by the client before rendering (just like sourceTexture)
    // ranges from 0.0 to 1.0 for darkening
    // ranges for 1.0 to ~infinty for brightening. capping around 10.0 or so works pretty well.

void main()
{
    vec3 target = vec3(0.0, 0.0, 0.0);
        // for brightness the target is black or zero intensity in each channel

    vec4 source = texture2D(sourceTexture, interpolatedTextureCoordinate);
        // sample the original pixel    
    
    // our formula is :
    //    (1-amount) * target + (amount * source)

    target = (1.0 - amount) * target;
    source.rgb = target + (amount * source.rgb);
        // for a completely black source, target is always zero, so we could simplfy this!
    
    gl_FragColor = source;
}
