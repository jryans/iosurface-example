#ifdef GL_ES
precision highp float;
#endif
#extension GL_OES_standard_derivatives : enable
uniform vec3      iResolution;
//uniform float     iGlobalTime;
// by Nikos Papadopoulos, 4rknova / 2013
// WTFPL License

#ifdef GL_ES
precision highp float;
#endif

//#define ENABLE_SCROLLING
const float S = 10.; // Scale

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = floor(fragCoord.xy
                    * vec2(iResolution.x / iResolution.y, 1)
#ifdef ENABLE_SCROLLING
                    + vec2(iGlobalTime, cos(iGlobalTime))
#endif // ENABLE_SCROLLING
                    );

    fragColor = vec4(vec3(mod(uv.x + uv.y, 2.)), 1);
}

void main() {
    vec4 color = vec4(0.0,0.0,0.0,1.0);
    mainImage( color, gl_FragCoord.xy );
    color.w = 1.0;
    gl_FragColor = color;
}