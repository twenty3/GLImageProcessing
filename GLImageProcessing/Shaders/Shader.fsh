//
//  Shader.fsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
