package main

import "core:fmt"
import b2 "odin_modules:box2c"
import rl "vendor:raylib"

Conversion :: struct {
	scale:         f32,
	tile_size:     f32,
	screen_width:  f32,
	screen_height: f32,
}

Entity :: struct {
	body_id: b2.Body_ID,
	texture: rl.Texture,
}

convert_world_to_screen :: proc(p: b2.Vec2, cv: Conversion) -> rl.Vector2 {
	return {cv.scale * p.x + 0.5 * cv.screen_width, 0.5 * cv.screen_height - cv.scale * p.y}
}

draw_entity :: proc(entity: ^Entity, cv: Conversion) {
	p := b2.body_get_world_point(entity.body_id, {-0.5 * cv.tile_size, 0.5 * cv.tile_size})
	radians := b2.body_get_angle(entity.body_id)

	ps := convert_world_to_screen(p, cv)

	texture_scale := cv.tile_size * cv.scale / f32(entity.texture.width)

	rl.DrawTextureEx(entity.texture, ps, -rl.RAD2DEG * radians, texture_scale, rl.WHITE)
}

main :: proc() {
	width :: 1280
	height :: 720

	rl.InitWindow(width, height, "odin-raylib-box2d")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	tile_size: f32 = 1.0
	scale: f32 = 50.0

	cv := Conversion{scale, tile_size, f32(width), f32(height)}

	world_def := b2.default_world_def()
	world_id := b2.create_world(&world_def)

	ground_texture := rl.LoadTexture("assets/ground.png")
	defer rl.UnloadTexture(ground_texture)
	box_texture := rl.LoadTexture("assets/box.png")
	defer rl.UnloadTexture(box_texture)

	tile_polygon := b2.make_square(0.5 * tile_size)

	ground_entities := make([]Entity, 20)

	for &entity, i in ground_entities {
		body_def := b2.default_body_def()
		body_def.position = {f32(1 * i - 10) * tile_size, -4.5 - 0.5 * tile_size}

		entity.body_id = b2.create_body(world_id, &body_def)
		entity.texture = ground_texture
		shape_def := b2.default_shape_def()
		b2.create_polygon_shape(entity.body_id, &shape_def, &tile_polygon)
	}

	box_entities := make([]Entity, 4)

	for &entity, i in box_entities {
		body_def := b2.default_body_def()
		body_def.type = .Dynamic
		body_def.position = {0.5 * tile_size * f32(i), -4.0 + tile_size * f32(i)}
		entity.body_id = b2.create_body(world_id, &body_def)
		entity.texture = box_texture

		shape_def := b2.default_shape_def()
		shape_def.restitution = 0.1
		b2.create_polygon_shape(entity.body_id, &shape_def, &tile_polygon)
	}

	pause := false

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()

		if rl.IsKeyPressed(rl.KeyboardKey.P) {
			pause = !pause
		}

		if !pause {
			dt := rl.GetFrameTime()
			b2.world_step(world_id, dt, 8)
		}

		{
			rl.BeginDrawing()
			defer rl.EndDrawing()

			rl.ClearBackground(rl.DARKGRAY)

			rl.DrawText(
				"Hello, Box2D!",
				(width - rl.MeasureText("Hello Box2D", 36)) / 2,
				50,
				36,
				rl.LIGHTGRAY,
			)

			for _, i in ground_entities {
				draw_entity(&ground_entities[i], cv)
			}

			for _, i in box_entities {
				draw_entity(&box_entities[i], cv)
			}
		}
	}
}
