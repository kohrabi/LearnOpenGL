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
    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,

    -0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5, -0.5,  0.5,

    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5, -0.5,
    -0.5, -0.5,  0.5,
    -0.5,  0.5,  0.5,

     0.5,  0.5,  0.5,
     0.5,  0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5,  0.5,  0.5,

    -0.5, -0.5, -0.5,
     0.5, -0.5, -0.5,
     0.5, -0.5,  0.5,
     0.5, -0.5,  0.5,
    -0.5, -0.5,  0.5,
    -0.5, -0.5, -0.5,

    -0.5,  0.5, -0.5,
     0.5,  0.5, -0.5,
     0.5,  0.5,  0.5,
     0.5,  0.5,  0.5,
    -0.5,  0.5,  0.5,
    -0.5,  0.5, -0.5,
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

lightShader : Shader;
shader : Shader;

prevTime : f32;
time : f32;
deltaTime : f32;

camera : Camera;
fov : f32 = 45.0;

lightPos :: glm.vec3{ 1.2, 1.0, 2.0 };

init :: proc () 
{
    // Shader
    success : b8;
    shader, success = shader_load("content/shaders/normal/vertexShader.vert", "content/shaders/normal/fragmentShader.frag");
    shader = shader;
    assert(success == true, "Failed to load shader");
    // ----------------

    stbi.set_flip_vertically_on_load(1);
 
    gl.GenVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.GenBuffers(VBO_COUNT, raw_data(VBOs));
    gl.GenBuffers(EBO_COUNT, raw_data(EBOs));
    
    gl.BindVertexArray(VAOs[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0]);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), (0));
    gl.EnableVertexAttribArray(0);
    
    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    
    shader_use(shader); // don't forget to activate the shader before setting uniforms!  
    shader_set(shader, "objectColor", glm.vec3{ 1.0, 0.5, 0.31 });
    shader_set(shader, "lightColor", glm.vec3{ 1.0, 1.0, 1.0 });
    
    lightShader, success = 
        shader_load("content/shaders/light/lightVertexShader.vert", "content/shaders/light/lightFragmentShader.frag");
    assert(success == true, "Failed to load shader");

    gl.BindVertexArray(VAOs[1]);

    gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0]);
    // gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
    gl.EnableVertexAttribArray(0);
     
    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

    gl.Enable(gl.DEPTH_TEST);

    camera.yaw = glm.radians_f32(-90.0);
    camera.pitch = 0.0;
    camera.position = glm.vec3{ 0.0, 0.0, 5.0, };
    camera_update_direction_vectors(&camera);
}

update :: proc() {
    prevTime = time;
    time = cast (f32) glfw.GetTime();
    deltaTime = time - prevTime;

    if (is_key_down(glfw.KEY_ESCAPE)) {
        glfw.SetWindowShouldClose(window, true);
    }

    cameraSpeed : f32 = 5 * deltaTime;
    if (is_key_down(glfw.KEY_W)) {
        camera.position += cameraSpeed * camera.front;
    }
    if (is_key_down(glfw.KEY_S)) {
        camera.position -= cameraSpeed * camera.front;
    }
    if (is_key_down(glfw.KEY_D)) {
        camera.position += cameraSpeed * camera.right;
    }
    if (is_key_down(glfw.KEY_A)) {
        camera.position -= cameraSpeed * camera.right;
    }
    fov = glm.clamp(fov - cast (f32) yScrollOffset, 1.0, 180.0);

    sensitivity :: 0.001;
    maxPitch :: 89.0 * glm.PI / 180.0;
    mouseOffset := mousePos - prevMousePos;
    mouseOffset *= sensitivity;
    camera.yaw += mouseOffset.x;
    camera.pitch = glm.clamp_f32(camera.pitch - mouseOffset.y, -maxPitch, maxPitch);
    camera_update_direction_vectors(&camera);
}

draw :: proc () {
    // Draw
    gl.ClearColor(0.2, 0.3, 0.3, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        
    projection = glm.mat4Perspective(glm.radians(fov), (f32)(screenWidth / screenHeight), 0.1, 100);

    radius :: 10.0;

    view = glm.mat4LookAt(camera.position, camera.position + camera.front, WORLD_UP);

    shader_use(shader); 

    gl.BindVertexArray(VAOs[0]);

    shader_set(shader, "view", view);
    shader_set(shader, "projection", projection);    
    shader_set(shader, "model", glm.identity(glm.mat4));
    gl.DrawArrays(gl.TRIANGLES, 0, 36);

    shader_use(lightShader);
    gl.BindVertexArray(VAOs[1]);
    shader_set(lightShader, "view", view);
    shader_set(lightShader, "projection", projection);    
    model : glm.mat4 = glm.identity(glm.mat4);
    model *= glm.mat4Translate(lightPos); 
    model *= glm.mat4Scale(glm.vec3{0.2, 0.2, 0.2});
    shader_set(lightShader, "model", model);
    gl.DrawArrays(gl.TRIANGLES, 0, 36);

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
        
        set_previous_input_state();
        
        glfw.SwapBuffers(window);
    }

    gl.DeleteVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.DeleteBuffers(VBO_COUNT, raw_data(VBOs));
    gl.DeleteBuffers(EBO_COUNT, raw_data(EBOs));
    gl.DeleteProgram(shader.id);
    gl.DeleteProgram(lightShader.id);

    return;
}
