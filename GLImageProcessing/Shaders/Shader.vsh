//
//  Shader.vsh
//  GLImageProcessing
//
//  Created by Chris Parrish on 8/22/11.
//  Copyright 2011 Aged & Distilled. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;

varying vec4 colorVarying;

uniform float translate;

void main()
{
    gl_Position = position;
    gl_Position.y += sin(translate) / 2.0;

    colorVarying = color;
}
