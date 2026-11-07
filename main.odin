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
		sizeX = 32,
		sizeY = 32,
		posX  = 15,
		posY  = 15,
		dir   = Direction.RIGHT,
	}

	level_grid := Grid {
		sizeX = 40,
		sizeY = 40,
	}

	accumulator: f32

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		draw_background(level_grid, snake)

		draw_apple()

		rl.DrawRectangle(
			snake.posX * snake.sizeX,
			snake.posY * snake.sizeY,
			snake.sizeX,
			snake.sizeY,
			rl.GREEN,
		)

		snake_movement(&snake)

		accumulator += rl.GetFrameTime()
		if accumulator >= TICK_RATE {
			accumulator -= TICK_RATE

			update_snake(&snake)
		}


		rl.EndDrawing()
	}
}

update_snake :: proc(snake: ^Snake) {
	if snake.dir == Direction.UP {
		snake.posY -= 1
	} else if snake.dir == Direction.DOWN {
		snake.posY += 1
	} else if snake.dir == Direction.RIGHT {
		snake.posX += 1
	} else if snake.dir == Direction.LEFT {
		snake.posX -= 1
	}
}

snake_movement :: proc(snake: ^Snake) {
	if rl.IsKeyPressed(.UP) {
		if snake.dir == Direction.UP {return}

		snake.dir = Direction.UP
	} else if rl.IsKeyPressed(.DOWN) {
		if snake.dir == Direction.DOWN {return}

		snake.dir = Direction.DOWN
	} else if rl.IsKeyPressed(.RIGHT) {
		if snake.dir == Direction.RIGHT {return}

		snake.dir = Direction.RIGHT
	} else if rl.IsKeyPressed(.LEFT) {
		if snake.dir == Direction.LEFT {return}

		snake.dir = Direction.LEFT
	}
}

draw_apple :: proc() {
	rl.DrawRectangle(9 * 32, 13 * 32, 32, 32, rl.RED)
}

draw_background :: proc(grid: Grid, snake: Snake) {
	for y in 0 ..< grid.sizeY {
		for x in 0 ..< grid.sizeX {
			c := rl.Color{25, 25, 25, 255} if (x + y) % 2 == 0 else rl.Color{32, 32, 32, 255}
			rl.DrawRectangle(x * snake.sizeX, y * snake.sizeY, snake.sizeX, snake.sizeY, c)
		}
	}
}
