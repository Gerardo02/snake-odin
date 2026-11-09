package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %m\n", leak.location, leak.size)
		}
		for bad in track.bad_free_array {
			fmt.printf("%v bad free at %v\n", bad.location, bad.memory)
		}
		mem.tracking_allocator_destroy(&track)
	}

	rl.InitWindow(WIN_W, WIN_H, "Snake")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	snake := Snake {
		body               = make([dynamic]Cell, 0, 64),
		current_direction  = .RIGHT,
		buffered_direction = .RIGHT,
	}
	defer delete(snake.body)

	append(&snake.body, Cell{15, 15}, Cell{14, 15}, Cell{13, 15})

	level_grid := Grid {
		sizeX = 25,
		sizeY = 25,
	}

	accumulator: f32
	ticked_frame := false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		ticked_frame = false
		rl.ClearBackground(rl.SKYBLUE)

		draw_background(level_grid, snake)

		draw_apple()
		draw_snake(&snake)

		snake_movement_direction(&snake)

		accumulator += rl.GetFrameTime()
		if accumulator >= TICK_RATE {
			accumulator -= TICK_RATE

			update_snake(&snake)
			ticked_frame = true
		}

		rl.EndDrawing()
	}
}

draw_snake :: proc(snake: ^Snake) {
	snake_color := rl.GREEN

	for cell in snake.body {
		rl.DrawRectangle(
			cell.pos_x * CELL_SIZE,
			cell.pos_y * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE,
			snake_color,
		)
	}
}

update_snake :: proc(snake: ^Snake) {
	for i := len(snake.body) - 1; i >= 0; i -= 1 {
		if i == 0 {
			if snake.buffered_direction == .UP {
				snake.body[i].pos_y -= 1
			} else if snake.buffered_direction == .DOWN {
				snake.body[i].pos_y += 1
			} else if snake.buffered_direction == .RIGHT {
				snake.body[i].pos_x += 1
			} else if snake.buffered_direction == .LEFT {
				snake.body[i].pos_x -= 1
			}

			break
		}
		snake.body[i] = snake.body[i - 1]
	}

	snake.current_direction = snake.buffered_direction
}

snake_movement_direction :: proc(snake: ^Snake) {
	if rl.IsKeyPressed(.UP) {
		if snake.current_direction == .UP || snake.current_direction == .DOWN {return}

		snake.buffered_direction = .UP
	} else if rl.IsKeyPressed(.DOWN) {
		if snake.current_direction == .DOWN || snake.current_direction == .UP {return}

		snake.buffered_direction = .DOWN
	} else if rl.IsKeyPressed(.RIGHT) {
		if snake.current_direction == .RIGHT || snake.current_direction == .LEFT {return}

		snake.buffered_direction = .RIGHT
	} else if rl.IsKeyPressed(.LEFT) {
		if snake.current_direction == .LEFT || snake.current_direction == .RIGHT {return}

		snake.buffered_direction = .LEFT
	}
}

draw_apple :: proc() {
	rl.DrawRectangle(9 * CELL_SIZE, 13 * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.RED)
}

draw_background :: proc(grid: Grid, snake: Snake) {
	for y in 0 ..< grid.sizeY {
		for x in 0 ..< grid.sizeX {
			c := rl.Color{25, 25, 25, 255} if (x + y) % 2 == 0 else rl.Color{32, 32, 32, 255}
			rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, c)
		}
	}
}
