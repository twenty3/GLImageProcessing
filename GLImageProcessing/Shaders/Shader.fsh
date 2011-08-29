//
//  Shader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

varying lowp vec4 colorVarying;
    // Vertex shader provides this value for each vertex. When we read it here, it will be interpolated (perspective correct) for the fragment we are coloring based on its location in respect each relevant vertex 

void main()
{
    // simply set the interpolated color for this fragment
    gl_FragColor = colorVarying;
}
