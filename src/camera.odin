package main

import glm "core:math/linalg/glsl"

WORLD_UP :: glm.vec3 { 0.0, 1.0, 0.0 }

Camera :: struct {
    position : glm.vec3,

    yaw: f32,
    pitch: f32,

    front : glm.vec3,
    up : glm.vec3,
    right : glm.vec3
}

// In radians
camera_set_rotation_euler :: proc (camera : ^Camera, yaw, pitch : f32) {
    camera.yaw = yaw;
    camera.pitch = pitch;

    camera_update_direction_vectors(camera);
}

// This should be called if you want to update shits from the struct
camera_update_direction_vectors :: proc (camera: ^Camera) {   
    cameraDirection : glm.vec3;
    cameraDirection.x = glm.cos(camera.yaw) * glm.cos(camera.pitch);
    cameraDirection.y = glm.sin(camera.pitch);
    cameraDirection.z = glm.sin(camera.yaw) * glm.cos(camera.pitch);
    
    camera.front = glm.normalize(cameraDirection);
    camera.right = glm.normalize(glm.cross(camera.front, WORLD_UP));
    camera.up = glm.normalize(glm.cross(camera.right, camera.front));  
}