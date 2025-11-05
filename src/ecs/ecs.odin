package ecs

import "core:crypto/_aes/ct64"
import glm "core:math/linalg/glsl"

Entity :: distinct u32;

System :: struct($ComponentRegistry : typeid, $CompType : typeid) {
    update: proc(ecs: ^Registry(ComponentRegistry), entity : Entity, component : CompType),
    render: proc(ecs: ^Registry(ComponentRegistry), entity : Entity, component : CompType),
}

ComponentStorage :: struct($T : typeid) {
    components: map[Entity]T,
}

Registry :: struct {
    entities: [dynamic]Entity,
    components:  map[typeid]rawptr,
    next_entity_id: Entity,
    // systems: [dynamic]System(any),
}

ecs_create :: proc() -> Registry {
    return Registry {
        next_entity_id = 1,
        components = make(map[typeid]rawptr),
        entities = make([dynamic]Entity, 0),
    };
}

ecs_destroy :: proc(ecs: ^Registry) {
    for type_id, component_map in ecs.components {
        free(component_map)
    }
    delete(ecs.components)
    delete(ecs.entities)
}

ecs_component_register :: proc(ecs: ^Registry, $compType : typeid) {
    if compType not_in ecs.components {
        storage := new(ComponentStorage(compType));
        storage^.components = make(map[Entity]compType);
        ecs.components[compType] = storage;
    }
}

ecs_component_get_storage :: proc(ecs: ^Registry, $compType : typeid) -> ^ComponentStorage(compType) {
    if compType in ecs.components {
        return cast(^ComponentStorage(compType))ecs.components[compType];
    }
    return nil;
}

ecs_entity_create :: proc(ecs: ^Registry) -> Entity {
    entity : Entity = ecs.next_entity_id;
    append(&ecs.entities, entity);
    ecs.next_entity_id += 1;
    return entity;
}

ecs_entity_add_component :: proc(ecs: ^Registry, entity: Entity, component: $compType) {
    if compType not_in ecs.components {
        ecs_component_register(ecs, compType);
    }
    storage := ecs_component_get_storage(ecs, compType);
    storage.components[entity] = component;
}

ecs_entity_get_component :: proc(ecs: ^Registry, entity: Entity, $compType: typeid) -> (compType, bool) {
    storage := ecs_component_get_storage(ecs, compType);
    if storage != nil {
        if entity in storage.components {
            return storage.components[entity], true;
        }
    }
    return {}, false
}
