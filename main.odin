package main

import rl "vendor:raylib"

WIN_W :: 1280
WIN_H :: 1280

Snake :: struct {
	size: i32,
	posX: i32,
	posY: i32,
}

Grid :: struct {
	sizeX: i32,
	sizeY: i32,
}

main :: proc() {
	rl.InitWindow(WIN_W, WIN_H, "Snake")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	snake := Snake {
		size = 32,
		posX = 15,
		posY = 15,
	}

	level_grid := Grid {
		sizeX = 40,
		sizeY = 40,
	}

	for !rl.WindowShouldClose() {
		// 1. read input (rl.IsKeyPressed(.UP), etc.)
		// 2. update: move snake on a timer, check food/walls/self
		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		draw_background(&level_grid, &snake)

		rl.DrawRectangle(
			snake.posX * snake.size,
			snake.posY * snake.size,
			snake.size,
			snake.size,
			rl.GREEN,
		)

		if rl.IsKeyPressed(.UP) {
			snake.posY -= 1
		} else if rl.IsKeyPressed(.DOWN) {
			snake.posY += 1
		} else if rl.IsKeyPressed(.RIGHT) {
			snake.posX += 1
		} else if rl.IsKeyPressed(.LEFT) {
			snake.posX -= 1
		}

		rl.EndDrawing()
	}
}

draw_background :: proc(grid: ^Grid, snake: ^Snake) {
	for y in 0 ..< grid.sizeY {
		for x in 0 ..< grid.sizeX {
			c := rl.Color{25, 25, 25, 255} if (x + y) % 2 == 0 else rl.Color{32, 32, 32, 255}
			rl.DrawRectangle(x * snake.size, y * snake.size, snake.size, snake.size, c)
		}
	}
}
