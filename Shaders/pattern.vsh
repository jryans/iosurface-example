attribute vec4 inVertex;

void main() {
    gl_Position = vec4(inVertex.xy,0.0,1.0);
}