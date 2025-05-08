package main

import "core:fmt"
import "core:c"
import "vendor:glfw"
import "core:os"
import "core:math"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

view : glm.mat4;
projection : glm.mat4;

vertices := [?]f32 {
    -0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0
};

cubePositions := [?]glm.vec3{
    {  0.0,  0.0,  0.0 }, 
    {  2.0,  5.0, -15.0 }, 
    { -1.5, -2.2, -2.5 },  
    { -3.8, -2.0, -12.3 },  
    {  2.4, -0.4, -3.5 },  
    { -1.7,  3.0, -7.5 },  
    {  1.3, -2.0, -2.5 },  
    {  1.5,  2.0, -2.5 }, 
    {  1.5,  0.2, -1.5 }, 
    { -1.3,  1.0, -1.5 }
}

shaderProgram : Shader;
texture : u32;
texture2 : u32;

init :: proc () 
{
    // Shader
    shader, success := shader_load("content/shaders/vertexShader.vert", "content/shaders/fragmentShader.frag");
    shaderProgram = shader;
    assert(success != 0, "Failed to load shader");
    // -----------------

    stbi.set_flip_vertically_on_load(1);
    width, height, nrChannels : i32;
    imageData := stbi.load("content/textures/wall.jpg", &width, &height, &nrChannels, 0);
    assert(imageData != nil, "Failed to load texture");
    width2, height2, nrChannels2 : i32;
    imageData2 := stbi.load("content/textures/awesomeface.png", &width2, &height2, &nrChannels2, 0);
    assert(imageData2 != nil, "Failed to load texture");
    
    gl.GenTextures(1, &texture);
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, imageData);
    gl.GenerateMipmap(gl.TEXTURE_2D);

    gl.GenTextures(1, &texture2);
    gl.BindTexture(gl.TEXTURE_2D, texture2);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width2, height2, 0, gl.RGBA, gl.UNSIGNED_BYTE, imageData2);
    gl.GenerateMipmap(gl.TEXTURE_2D);
   
    gl.GenVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.GenBuffers(VBO_COUNT, raw_data(VBOs));
    gl.GenBuffers(EBO_COUNT, raw_data(EBOs));
    
    gl.BindVertexArray(VAOs[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0]);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);
    
    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBOs[0]); 
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW);
    
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), (0));
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), (3 * size_of(f32)));
    gl.EnableVertexAttribArray(1);
    // gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), (6 * size_of(f32)));
    // gl.EnableVertexAttribArray(2);

    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    stbi.image_free(imageData)    
    stbi.image_free(imageData2)

    shader_use(shaderProgram); // don't forget to activate the shader before setting uniforms!  
    shader_set_int(shaderProgram, "mainTexture", 0);
    shader_set_int(shaderProgram, "texture1", 1);
    fmt.println("Successful :D");

    gl.Enable(gl.DEPTH_TEST);

}

update :: proc() {
    processInput(window);
}

draw :: proc () {
    // Draw
    time : f32 = cast (f32) glfw.GetTime();
        
    view = glm.identity(glm.mat4);
    view *= glm.mat4Translate(glm.vec3{ 0.0, 0.0, -3.0 });
    
    projection = glm.mat4Perspective(glm.radians_f32(45.0), cast (f32)SCREEN_WIDTH / cast (f32)SCREEN_HEIGHT, 0.1, 100);
    
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
    shader_use(shaderProgram); 
    
    gl.ActiveTexture(gl.TEXTURE0);
    gl.BindTexture(gl.TEXTURE_2D, texture);
    
    gl.ActiveTexture(gl.TEXTURE1);
    gl.BindTexture(gl.TEXTURE_2D, texture2);
    
    gl.BindVertexArray(VAOs[0]);

    shader_set_mat4(shaderProgram, "view", view);
    shader_set_mat4(shaderProgram, "projection", projection);     
    for pos, index in cubePositions {
        model := glm.identity(glm.mat4);
        model *= glm.mat4Translate(pos);
        if (index % 3 == 0) {
            model *= glm.mat4Rotate(glm.vec3{ 0.5, 1.0, 0.0 }, time * glm.radians_f32(-55.0));
        }
        else {
            model *= glm.mat4Rotate(glm.vec3{ 0.5, 1.0, 0.0 }, glm.radians_f32(-55.0));  
        }
        shader_set_mat4(shaderProgram, "model", model);
        gl.DrawArrays(gl.TRIANGLES, 0, 36);
    }

    gl.BindVertexArray(0);
}

main :: proc() {
    opengl_init()
    defer opengl_destroy()
    
    init();
    
    for (!glfw.WindowShouldClose(window)) {
        glfw.PollEvents();
        
        update();

        draw();
        
        glfw.SwapBuffers(window);
    }

    gl.DeleteVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.DeleteBuffers(VBO_COUNT, raw_data(VBOs));
    gl.DeleteBuffers(EBO_COUNT, raw_data(EBOs));
    gl.DeleteProgram(shaderProgram.id);

    return;
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height);
}

processInput :: proc (window: glfw.WindowHandle) {
    if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
        glfw.SetWindowShouldClose(window, true);
    }
}