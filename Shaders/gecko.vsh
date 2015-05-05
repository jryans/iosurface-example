uniform mat4 uMatrixProj;
uniform vec4 uLayerRects[4];
uniform mat4 uLayerTransform;
uniform vec4 uRenderTargetOffset;
attribute vec4 aCoord;
uniform mat4 uTextureTransform;
uniform vec4 uTextureRects[4];
varying vec2 vTexCoord;
void main() {
    int vertexID = int(aCoord.w);
    vec4 layerRect = uLayerRects[vertexID];
    vec4 finalPosition = vec4(aCoord.xy * layerRect.zw + layerRect.xy, 0.0, 1.0);
    finalPosition = uLayerTransform * finalPosition;
    finalPosition.xyz /= finalPosition.w;
    finalPosition = finalPosition - uRenderTargetOffset;
    finalPosition.xyz *= finalPosition.w;
    finalPosition = uMatrixProj * finalPosition;
    vec4 textureRect = uTextureRects[vertexID];
    vec2 texCoord = aCoord.xy * textureRect.zw + textureRect.xy;
    vTexCoord = (uTextureTransform * vec4(texCoord, 0.0, 1.0)).xy;
    gl_Position = finalPosition;
}
