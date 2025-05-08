package main

import "core:os"
import "core:fmt"
import gl "vendor:OpenGL"

Shader :: struct {
    id : u32,
    vertexPath : string,
    fragmentPath : string,
}

use_shader :: proc (shader : Shader) {
    gl.UseProgram(shader.id);
}

load_shader :: proc (vertexPath : string, fragmentPath : string) -> (shader : Shader, success: int) {    
    shader = { 0, vertexPath, fragmentPath };
    success = 0;
    vertexShader : u32 = load_shader_file(gl.VERTEX_SHADER, "vertexShader.vert");
    fragmentShader : u32 = load_shader_file(gl.FRAGMENT_SHADER, "fragmentShader.frag");
    shader.id = gl.CreateProgram();
    gl.AttachShader(shader.id, vertexShader);
    gl.AttachShader(shader.id, fragmentShader);
    gl.LinkProgram(shader.id);
    
    programSuccess : i32;
    infoLog : [^]byte;
    gl.GetProgramiv(shader.id, gl.LINK_STATUS, &programSuccess); 
    if programSuccess == 0 {
        gl.GetShaderInfoLog(shader.id, 512, nil, infoLog);
        fmt.eprintfln("ERROR SHADER LINK FAILURE\n%s", infoLog);
        return
    }
    success = 1;
    gl.DeleteShader(vertexShader);
    gl.DeleteShader(fragmentShader);
    return
}

set_float :: proc (shader : Shader, name : cstring, value : f32) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform1f(location, value);
}

set_vec2 :: proc (shader : Shader, name : cstring, value : vec2) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform2f(location, value.x, value.y);
}

set_vec3 :: proc (shader : Shader, name : cstring, value : vec3) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform3f(location, value.x, value.y, value.z);
}

set_vec4 :: proc (shader : Shader, name : cstring, value : vec4) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform4f(location, value.x, value.y, value.z, value.w);
}

set_int :: proc (shader : Shader, name : cstring, value : i32) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform1i(location, value);
}

@(private="file")
load_shader_file :: proc (type: u32, file_name : string) -> u32 {
    
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
    infoLog := make([]u8, 512);
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &shaderSuccess); 
    if shaderSuccess == 0 {
        gl.GetShaderInfoLog(shader, 512, nil, raw_data(infoLog));
        fmt.eprintfln("ERROR SHADER %s COMPILATION FAILURE\n", (type == gl.VERTEX_SHADER ? "Vertex" : "Fragment"));
        fmt.eprintfln("%s", string(infoLog));
        delete(infoLog);
        return 0;
    }
    return shader;
}