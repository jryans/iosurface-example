#version 150

in vec2 textureCoord;
out vec4 fragColor;

uniform sampler2DRect tex;

void main()
{
	fragColor = texture(tex, textureCoord);
}
