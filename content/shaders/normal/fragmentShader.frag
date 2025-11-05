#version 330 core

out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 viewPos;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
}; 
  

struct Light {
    vec3 position;
  
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform Material material;
uniform Light light;  

in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoords;

void main()
{
    vec3 diffuseColor = texture(material.diffuse, TexCoords).rgb;
    vec3 specularColor = texture(material.specular, TexCoords).rgb;
    // Phong lighting model
    // ambient light
    vec3 ambient = light.ambient * diffuseColor;

    // diffuse light
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(light.position - FragPos);
    float diff = max(dot(norm, lightDir), 0.0f);
    vec3 diffuse = light.diffuse * (diff * diffuseColor);

    // specular light
    float specularStrength = 0.5f;
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);

    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * (spec * specularColor);  

    vec3 result = (ambient + diffuse + specular);

    FragColor = vec4(result, 1.0f);
} 