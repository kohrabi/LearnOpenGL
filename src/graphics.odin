package main

import "vendor:glfw"
import "core:fmt"
import "core:strconv"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"
import glm "core:math/linalg/glsl"
import "base:runtime"

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

screenWidth : i32 = SCREEN_WIDTH;
screenHeight : i32 = SCREEN_HEIGHT;
prevKeyDown : [350]b8;
keyDown : [350]b8;
keyMods : i8;
mousePos : glm.vec2;
prevMousePos : glm.vec2;
yScrollOffset : f64;

texture_load :: proc(path : string) -> (texture: u32, width, height, nrChannels: i32) {
    imageData := stbi.load("content/textures/wall.jpg", &width, &height, &nrChannels, 0);
    assert(imageData != nil, "Failed to load texture");

    defer stbi.image_free(imageData);

    gl.GenTextures(1, &texture);
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, imageData);
    gl.GenerateMipmap(gl.TEXTURE_2D);
    return
}

opengl_init :: proc () {

     // Init OpenGL
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, OPENGL_VERSION_MAJOR);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, OPENGL_VERSION_MINOR);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);

    assert(glfw.Init() == glfw.TRUE, "Failed to initialize GLFW")
    
    window = glfw.CreateWindow(screenWidth, screenHeight, "Learn OpenGL", nil, nil);
    
    assert(window != nil, "Failed to create GLFW window");
        
    glfw.SetErrorCallback(error_callback);
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED);
    glfw.SetCursorPosCallback(window, mouse_callback);
    glfw.SetKeyCallback(window, key_callback);
    glfw.SetScrollCallback(window, scroll_callback);
   
    glfw.MakeContextCurrent(window);
    glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback);
    gl.load_up_to(OPENGL_VERSION_MAJOR, OPENGL_VERSION_MINOR, glfw.gl_set_proc_address);

    gl.Viewport(0, 0, screenWidth, screenHeight);

    fmt.println("Initialize OpenGL Successful!");
}

opengl_destroy :: proc () {
    glfw.DestroyWindow(window)
    glfw.Terminate()
}

set_previous_input_state :: proc() {
    for &key, index in prevKeyDown {
        key = keyDown[index];
    }
    prevMousePos = mousePos;
    yScrollOffset = 0.0;
}

is_key_down :: proc(keyCode : i32) -> b8 { return keyDown[keyCode]; }
is_key_just_pressed :: proc(keyCode : i32) -> b8 { return keyDown[keyCode] && !prevKeyDown[keyCode]; }
is_key_just_released :: proc(keyCode : i32) -> b8 { return !keyDown[keyCode] && prevKeyDown[keyCode]; }
is_key_mode_down :: proc(keyModCode : i8) -> b8 { return (keyMods & keyModCode) > 0;  }

error_callback :: proc "c"(errorCode: i32, description: cstring) {
    context = runtime.default_context();
    fmt.eprintln(description, errorCode);
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
    screenWidth = width;
    screenHeight = height;
    gl.Viewport(0, 0, screenWidth, screenHeight);
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods : i32) {
    if (action == glfw.PRESS) {
        keyDown[key] = true;
    }
    else if (action == glfw.RELEASE) {
        keyDown[key] = false;
    }
    keyMods = cast (i8) mods;
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64) {
    mousePos = glm.vec2{cast (f32) xpos, cast (f32) ypos};
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xOffset, yOffset : f64) {
    yScrollOffset = yOffset;
}