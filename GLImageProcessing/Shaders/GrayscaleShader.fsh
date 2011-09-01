//
//  GrayscaleShader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

precision mediump float;
varying vec2 interpolatedTextureCoordinate;
    // Vertex shader provides this value for each vertex. When we read it here, it will be interpolated (perspective correct) for the fragment we are coloring based on its location in respect each relevant vertex 

uniform sampler2D sourceTexture;
    // This uniform is of the special type sampler2D. The value of this type is the texture unit to sample from. The value should be provided by the client and should be the texture unit we have bound our source texture too in the GL state.

void main()
{
    // Grayscale conversion is a weighted average of the RGB components, where green contributes the most, red the next and blue the least. The exect coefficients to use depends on the gamma of the original image and a variety of other factors including what is perhaps pleasing asthetically. The values used here are assume a linear-gamma source and presentation on a modern diplay
    vec3 coefficients = vec3(0.2125, 0.7154, 0.0721);

    vec4 source = texture2D(sourceTexture, interpolatedTextureCoordinate);
        // sample the original pixel    
    
    float l = dot(coefficients, source.rgb);
        // use the dot product operator on the RGB values of the source. This is effectively (c1 * r) + (c2 * g) + (c3 * b)
    
    source.rgb = vec3(l, l, l);
        // use the luminance value for each of the 3 components. Note that alpha is preserved
    
    gl_FragColor = source;
}
