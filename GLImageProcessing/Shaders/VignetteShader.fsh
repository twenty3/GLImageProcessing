//
//  VignetteShader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

precision highp float;

varying vec2 interpolatedTextureCoordinate;
uniform sampler2D sourceTexture;
uniform float amount;
    // this controls the radius of the vignette. Suggested values are [0 .. 50]

const float PI = 3.14159265358979323846264;

const vec4 backgroundColor = vec4(0.0, 0.0, 0.0, 1.0);
    // this could be a uniform from the client to expose control of the color

const vec2 center = vec2(0.5, 0.5);
    // this could also be a uniform from the client to expose control of the center

void main()
{
    // Use a 2-D radial gaussain to blend source with background color

    vec4 source = texture2D(sourceTexture, interpolatedTextureCoordinate);
    float sigma = amount;
        // sigma in the gaussian equation controls the shape of the bell
        // in our use this is effectively the radius of the vignette

    float distance = distance(center, interpolatedTextureCoordinate);
    float alpha = 2.0 * (1.0 / sqrt(2.0 * PI)) * exp((-sigma) * pow(distance, 2.0));
    //alpha = clamp(alpha, 0.0, 1.0);
        // make sure alpha is always between 0 and 1

    gl_FragColor = mix(backgroundColor, source, alpha);

    // This code can give you a way to visualize the curve we are using for blending
    //gl_FragColor = vec4(alpha, alpha, alpha, 1.0);
}
