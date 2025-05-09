#version 330 core

out vec4 FragColor;

in vec2 TexCoord;
uniform sampler2D mainTexture;
uniform sampler2D texture1;

void main()
{
    FragColor = mix(texture(mainTexture, TexCoord), texture(texture1, TexCoord), 0.2);
} 