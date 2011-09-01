//
//  RippleShader.fsh
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
    // this controls the # of ripples. Suggested values are [0 .. 100]

const float PI = 3.14159265358979323846264;

void main()
{
    // We can simulate a water ripple with a sin wave that is 'dampened' by a gaussian (bell curve)

    //  we sample from the source texture based on the distance from the pixel we are sampling from the center. That distance is the parameter to a the dampened sin fucntion. The new coordinate is the pixel we will actually sample for the output

    float	amplitude       = 0.03;
        // amplitude of ripples 0.0 - 1.0 are good values
    vec2	position 		= vec2(0.5, 0.5);
        // center of the ripple in texture coordinates. This puts it in the center
    float   sigma           = 5.0;
        // shape of gaussian bell that controls dampenning 

    float distance	= distance(position, interpolatedTextureCoordinate);
    float sinCurve	= (sin ( amount * distance *  2.0 * PI) * amplitude );
    float dampened	= (1.0 / sqrt(2.0 * PI)) * exp((-sigma) * pow(distance, 2.0)) * sinCurve;

    vec2 displacedCoordinate = vec2(interpolatedTextureCoordinate.x + dampened, interpolatedTextureCoordinate.y + dampened);
    vec4 source = texture2D(sourceTexture, displacedCoordinate);
        // sample the 'displaced' pixel    
    
    gl_FragColor = source;
   
    // This code can give you a way to visualize the curve we are using for displacement
    //float boosted = dampened * 100.0;
    //gl_FragColor = vec4(boosted, boosted, boosted, 1.0);
}
