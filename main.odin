package main

import "core:fmt"
import "core:c"
import "vendor:glfw"
import "core:os"
import "core:math"
import gl "vendor:OpenGL"

SCREEN_WIDTH :: 800;
SCREEN_HEIGHT :: 600;

OPENGL_VERSION_MAJOR :: 3;
OPENGL_VERSION_MINOR :: 3;

VAO_COUNT :: 2;
VBO_COUNT :: 2;
EBO_COUNT :: 2;

VAOs := make([]u32, VAO_COUNT);
VBOs := make([]u32, VBO_COUNT);
EBOs := make([]u32, EBO_COUNT);
window : glfw.WindowHandle;

main :: proc() {
    // Init OpenGL
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    
    if(glfw.Init() != glfw.TRUE){
        // Print Line
        fmt.eprintln("Failed to initialize GLFW")
        // Return early
        return
    }
    
    window = glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Learn OpenGL", nil, nil);
    
    defer glfw.Terminate()
    defer glfw.DestroyWindow(window)
    if (window == nil) {
        fmt.eprintln("Failed to create GLFW window");
        return;
    }
    
    glfw.MakeContextCurrent(window);
    glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback);
    gl.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address);

    gl.Viewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);


    nrAttributes : i32;
    gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttributes);
    fmt.printfln("Maximum nr of vertex attributes supported: %d", nrAttributes);

    // Shader
    shaderProgram, success := load_shader("vertexShader.vert", "fragmentShader.frag");
    assert(success != 0, "Failed to load shader");
    // -----------------

    vertices := [?]f32 {
        // positions         // colors
        0.5, -0.5, 0.0,  1.0, 0.0, 0.0,   // bottom right
        -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,   // bottom let
        0.0,  0.5, 0.0,  0.0, 0.0, 1.0    // top 
    };
    
    indices := [?]u32 {
        0, 1, 2, // first triangle 
        0, 1, 2
    }
    
    gl.GenVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.GenBuffers(VBO_COUNT, raw_data(VBOs));
    gl.GenBuffers(EBO_COUNT, raw_data(EBOs));
    
    gl.BindVertexArray(VAOs[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0]);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBOs[0]); 
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW);
    
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), (0));
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), (3 * size_of(f32)));
    gl.EnableVertexAttribArray(1);


    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

    fmt.println("Successful :D");
    for (!glfw.WindowShouldClose(window)) {
        processInput(window);
        
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        
        use_shader(shaderProgram); 

        timeValue : f64 = glfw.GetTime();
        greenValue : f32 = f32((math.sin(timeValue) / 2.0) + 0.5);
        set_float(shaderProgram, "xOffset", greenValue);
        
        gl.BindVertexArray(VAOs[0]);
        gl.DrawElements(gl.TRIANGLES, 3, gl.UNSIGNED_INT, nil);
        gl.BindVertexArray(0);
        
        glfw.SwapBuffers(window);
        glfw.PollEvents();
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