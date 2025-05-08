#version 330 core
out vec4 FragColor;

in vec3 vertexPos; 
in vec4 vertexColor; // the input variable from the vertex shader (same name and same type)  

void main()
{
    FragColor = vec4(vertexPos, 1.0); 
} 