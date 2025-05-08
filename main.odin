package main

import "core:fmt"
import "core:c"
import "vendor:glfw"
import "core:os"
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

    // Shader
    vertexShader : u32 = load_shader(gl.VERTEX_SHADER, "vertexShader.vert");
    fragmentShader : u32 = load_shader(gl.FRAGMENT_SHADER, "fragmentShader.frag");
    shaderProgram : u32 = gl.CreateProgram();
    gl.AttachShader(shaderProgram, vertexShader);
    gl.AttachShader(shaderProgram, fragmentShader);
    gl.LinkProgram(shaderProgram);

    programSuccess : i32;
    infoLog : [^]byte;
    gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &programSuccess); 
    if programSuccess == 0 {
        gl.GetShaderInfoLog(shaderProgram, 512, nil, infoLog);
        fmt.eprintfln("ERROR SHADER LINK FAILURE\n%s", infoLog);
        return;
    }
    
    gl.DeleteShader(vertexShader);
    gl.DeleteShader(fragmentShader);
    // -----------------

    vertices := [?]f32 {
         0.5,   0.5,  0.0,  // top right
         0.5,  -0.5,  0.0,  // bottom right
        -0.5,  -0.5, 0.0,  // bottom left
        -0.5,   0.5, 0.0   // top left 
    };
    
    indices := [?]u32 {
        0, 1, 3, // first triangle 
        1, 2, 3  // second TRIANGLES
    }
    
    gl.GenVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.GenBuffers(VBO_COUNT, raw_data(VBOs));
    gl.GenBuffers(EBO_COUNT, raw_data(EBOs));
    
    gl.BindVertexArray(VAOs[0]);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0]);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW);
    
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBOs[0]); 
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW);
    
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
    gl.EnableVertexAttribArray(0);

    gl.BindVertexArray(0);
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

    fmt.println("Successful :D");
    for (!glfw.WindowShouldClose(window)) {
        processInput(window);
        
        gl.ClearColor(0.2, 0.3, 0.3, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        
        gl.UseProgram(shaderProgram);
        gl.BindVertexArray(VAOs[0]);
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil);
        gl.BindVertexArray(0);
        
        glfw.SwapBuffers(window);
        glfw.PollEvents();
    }

    gl.DeleteVertexArrays(VAO_COUNT, raw_data(VAOs));
    gl.DeleteBuffers(VBO_COUNT, raw_data(VBOs));
    gl.DeleteBuffers(EBO_COUNT, raw_data(EBOs));
    gl.DeleteProgram(shaderProgram);

    return;
}

load_shader :: proc (type: u32, file_name : string) -> u32 {
    
    data, success := os.read_entire_file_from_filename(file_name);
    if !success {
        fmt.eprintln("Unable to read file");
        return 0;
    }
    shaderSource : cstring = cstring(raw_data(data));

    shader : u32 = gl.CreateShader(type);
    gl.ShaderSource(shader, 1, &shaderSource, nil);
    gl.CompileShader(shader);

    shaderSuccess : i32;
    infoLog : [^]byte;
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &shaderSuccess); 
    if shaderSuccess == 0 {
        gl.GetShaderInfoLog(shader, 512, nil, infoLog);
        fmt.eprintfln("ERROR SHADER %s COMPILATION FAILURE\n", (type == gl.VERTEX_SHADER ? "Vertex" : "Fragment"));
        fmt.eprintfln("%s", infoLog);
        return 0;
    }
    return shader;
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    gl.Viewport(0, 0, width, height);
}

processInput :: proc (window: glfw.WindowHandle) {
    if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
        glfw.SetWindowShouldClose(window, true);
    }
}