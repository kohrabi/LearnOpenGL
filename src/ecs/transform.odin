package ecs

import glm "core:math/linalg/glsl"

Transform :: struct {
    position: glm.vec3,
    rotation: glm.vec3,
    scale:    glm.vec3,
}