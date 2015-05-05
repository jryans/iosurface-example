#extension GL_ARB_texture_rectangle : require
#ifdef GL_ES
precision mediump float;
#define COLOR_PRECISION lowp
#else
#define COLOR_PRECISION
#endif
varying vec2 vTexCoord;
uniform vec2 uTexCoordMultiplier;
uniform sampler2DRect uTexture;
vec4 sample(vec2 coord) {
    vec4 color;
    color = texture2DRect(uTexture, coord);
    return color;
}
void main() {
    vec4 color = sample(vTexCoord * uTexCoordMultiplier);
    COLOR_PRECISION float mask = 1.0;
    color *= mask;
    gl_FragColor = color;
}
