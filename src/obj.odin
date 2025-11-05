package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strconv"

Model_Data :: struct {
	vertex_positions:  []glm.vec3,
	vertex_normals:    []glm.vec3,
	vertex_uvs:        []glm.vec2,
	indices_positions: []i32,
	indices_normals:   []i32,
	indices_uvs:       []i32,
}

free_model_data :: proc(model_data: Model_Data) {
	free(raw_data(model_data.vertex_positions))
    free(raw_data(model_data.vertex_normals))
    free(raw_data(model_data.vertex_uvs))
    free(raw_data(model_data.indices_positions))
    free(raw_data(model_data.indices_normals))
    free(raw_data(model_data.indices_uvs))
}

print_model_data :: proc(model_data: Model_Data, N: int) {
	for v in model_data.vertex_positions {
		fmt.printf("v.x: %v\n", v.x)
		fmt.printf("v.y: %v\n", v.y)
		fmt.printf("v.z: %v\n", v.z)
	}
	for v in model_data.vertex_normals {
		fmt.printf("v.x: %v\n", v.x)
		fmt.printf("v.y: %v\n", v.y)
		fmt.printf("v.z: %v\n", v.z)
	}
	for v in model_data.vertex_uvs {
		fmt.printf("v.x: %v\n", v.x)
		fmt.printf("v.y: %v\n", v.y);
	}

	for i in 0 ..< N do fmt.printf("fv[%d]: %d %d %d\n", i, model_data.indices_positions[3 * i + 0], model_data.indices_positions[3 * i + 1], model_data.indices_positions[3 * i + 2])
	for i in 0 ..< N do fmt.printf("fvn[%d]: %d %d %d\n", i, model_data.indices_normals[3 * i + 0], model_data.indices_normals[3 * i + 1], model_data.indices_normals[3 * i + 2])
	for i in 0 ..< N do fmt.printf("fvt[%d]: %d %d %d\n", i, model_data.indices_uvs[3 * i + 0], model_data.indices_uvs[3 * i + 1], model_data.indices_uvs[3 * i + 2])
}

stream: string

is_whitespace :: #force_inline proc(c: u8) -> bool {
	switch c {
	case ' ', '\t', '\n', '\v', '\f', '\r', '/':
		return true
	}
	return false
}

skip_whitespace :: #force_inline proc() #no_bounds_check {
	for stream != "" && is_whitespace(stream[0]) {
		stream = stream[1:]
	}
}

skip_line :: proc() #no_bounds_check {
	N := len(stream)
	for i := 0; i < N; i += 1 {
		if stream[0] == '\r' || stream[0] == '\n' {
			skip_whitespace()
			return
		}
		stream = stream[1:]
	}
}

next_word :: proc() -> string #no_bounds_check {
	skip_whitespace()

	for i := 0; i < len(stream); i += 1 {
		if is_whitespace(stream[i]) || i == len(stream) - 1 {
			current_word := stream[0:i]
			stream = stream[i + 1:]
			return current_word
		}
	}
	return ""
}

// @WARNING! This assumes the obj file is well formed.
//
//   Each v, vn line has to have at least 3 elements. Every element after the third is discarded
//   Each vt line has to have at least 2 elements. Every element after the second is discarded
//   Each f line has to have at least 9 elements. Every element after the ninth is discarded
//
//   Note that we only support files where the faces are specified as A/A/A B/B/B C/C/C
//   Note also that '/' is regarded as whitespace, to simplify the face parsing
read_obj :: proc(filename: string) -> (Model_Data, bool) #no_bounds_check {
	to_f32 :: proc(str: string) -> f32 { value, ok := strconv.parse_f32(str); return cast(f32)value; }
	to_i32 :: proc(str: string) -> i32 { value, ok := strconv.parse_int(str); return cast(i32)value; }

	data, status := os.read_entire_file(filename)
	if !status do return Model_Data{}, false
	defer if(len(data) > 0) { free(raw_data(data)) }

	vertex_positions: [dynamic]glm.vec3
	vertex_normals: [dynamic]glm.vec3
	vertex_uvs: [dynamic]glm.vec2
	indices_positions: [dynamic]i32
	indices_normals: [dynamic]i32
	indices_uvs: [dynamic]i32

	defer delete(vertex_positions)
	defer delete(vertex_normals)
	defer delete(vertex_uvs)
	defer delete(indices_positions)
	defer delete(indices_normals)
	defer delete(indices_uvs)

	stream = string(data)
	for stream != "" {
		current_word := next_word()

		switch current_word {
		case "v":
			append(
				&vertex_positions,
				glm.vec3{to_f32(next_word()), to_f32(next_word()), to_f32(next_word())},
			)
		case "vn":
			append(
				&vertex_normals,
				glm.vec3{to_f32(next_word()), to_f32(next_word()), to_f32(next_word())},
			)
		case "vt":
			append(&vertex_uvs, glm.vec2{to_f32(next_word()), to_f32(next_word())})
		case "f":
			indices: [9]i32
			for i in 0 ..< 9 do indices[i] = to_i32(next_word()) - 1
			append(&indices_positions, indices[0], indices[3], indices[6])
			append(&indices_normals, indices[1], indices[4], indices[7])
			append(&indices_uvs, indices[2], indices[5], indices[8])
		}
		skip_line()
	}

	fmt.printf(
		"vertex positions = %d, vertex normals = %d, vertex uvs = %d\n",
		len(vertex_positions),
		len(vertex_normals),
		len(vertex_uvs),
	)
	fmt.printf(
		"indices positions = %d, indices normals = %d, indices uvs = %d\n",
		len(indices_positions),
		len(indices_normals),
		len(indices_uvs),
	)

	return Model_Data {
			vertex_positions[:],
			vertex_normals[:],
			vertex_uvs[:],
			indices_positions[:],
			indices_normals[:],
			indices_uvs[:],
		},
		true
}
