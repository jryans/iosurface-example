#version 150

in vec4 inVertex, inTexCoord;
out vec2 textureCoord;

uniform mat4 MVP;

void main()
{
	gl_Position = MVP * inVertex;
    textureCoord = inTexCoord.st;
}
