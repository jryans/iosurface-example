#version 150

in vec4 inVertex;
out vec4 color;

uniform mat4 MVP;
uniform vec4 constantColor;

void main()
{
	gl_Position = MVP * inVertex;
    color = constantColor;
}
