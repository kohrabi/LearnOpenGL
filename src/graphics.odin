package main

import "vendor:glfw"
import "core:fmt"
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


opengl_init :: proc () {
     // Init OpenGL
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    
    assert(glfw.Init() == glfw.TRUE, "Failed to initialize GLFW")
    
    window = glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Learn OpenGL", nil, nil);
    
    assert(window != nil, "Failed to create GLFW window");
    
    glfw.MakeContextCurrent(window);
    glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback);
    gl.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address);

    gl.Viewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    nrAttributes : i32;
    gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttributes);
    fmt.printfln("Maximum nr of vertex attributes supported: %d", nrAttributes);
}

opengl_destroy :: proc () {
    glfw.DestroyWindow(window)
    glfw.Terminate()
}