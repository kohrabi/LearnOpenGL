package main

import "core:os"
import "core:fmt"
import gl "vendor:OpenGL"
import "core:math/linalg"
import glm "core:math/linalg/glsl"

Shader :: struct {
    id : u32,
    vertexPath : string,
    fragmentPath : string,
}

shader_use :: proc (shader : Shader) {
    gl.UseProgram(shader.id);
}

shader_load :: proc (vertexPath : string, fragmentPath : string) -> (shader : Shader, success: int) {    
    shader = { 0, vertexPath, fragmentPath };
    success = 0;
    vertexShader : u32 = shader_load_shader_file(gl.VERTEX_SHADER, vertexPath);
    fragmentShader : u32 = shader_load_shader_file(gl.FRAGMENT_SHADER, fragmentPath);
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

    defer gl.DeleteShader(vertexShader);
    defer gl.DeleteShader(fragmentShader);

    return
}

shader_set :: proc { shader_set_mat4, shader_set_float, shader_set_vec2, shader_set_vec3, shader_set_vec4, shader_set_int }

shader_set_mat4 :: proc (shader : Shader, name : cstring, value : glm.mat4) {
    location := gl.GetUniformLocation(shader.id, name);
    matrixFlatten := linalg.matrix_flatten(value);
    gl.UniformMatrix4fv(location, 1, gl.FALSE, raw_data(&matrixFlatten));
}

shader_set_float :: proc (shader : Shader, name : cstring, value : f32) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform1f(location, value);
}

shader_set_vec2 :: proc (shader : Shader, name : cstring, value : glm.vec2) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform2f(location, value.x, value.y);
}

shader_set_vec3 :: proc (shader : Shader, name : cstring, value : glm.vec3) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform3f(location, value.x, value.y, value.z);
}

shader_set_vec4 :: proc (shader : Shader, name : cstring, value : glm.vec4) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform4f(location, value.x, value.y, value.z, value.w);
}

shader_set_int :: proc (shader : Shader, name : cstring, value : i32) {
    location := gl.GetUniformLocation(shader.id, name);
    gl.Uniform1i(location, value);
}

@(private="file")
shader_load_shader_file :: proc (type: u32, file_name : string) -> u32 {
    
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