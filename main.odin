package main

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:slice"
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

	game_state: Game_State = .GAME
	score := 0

	snake := Snake {
		body              = make([dynamic]Cell, 0, 64),
		current_direction = .RIGHT,
	}
	defer delete(snake.body)

	apple := Cell{9, 13}

	append(&snake.body, Cell{15, 15})

	level_grid := Grid {
		size_x = 25,
		size_y = 25,
	}

	accumulator: f32
	ticked_frame := false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		ticked_frame = false
		rl.ClearBackground(rl.SKYBLUE)

		switch game_state {
		case .MENU:
			game_state = .GAME
			break
		case .GAME:
			draw_background(level_grid, snake)

			draw_apple(apple)
			draw_snake(&snake)

			snake_movement_direction(&snake)

			accumulator += rl.GetFrameTime()
			if accumulator >= TICK_RATE {
				accumulator -= TICK_RATE

				update_snake(&snake)

				if hit_self(snake.body[:]) || hit_wall(snake.body[0], level_grid) {
					game_state = .DEAD
					break
				}

				ticked_frame = true
			}

			if snake.body[0] == apple {
				eat_apple(&apple, &snake, level_grid)
				score += 1
			}

			if rl.IsKeyPressed(.R) {
				restart_game(&snake, &game_state, &score)
				eat_apple(&apple, &snake, level_grid)
			} else if rl.IsKeyPressed(.SPACE) {
				game_state = .PAUSE
				break
			}
		case .DEAD:
			draw_background(level_grid, snake)

			draw_apple(apple)
			draw_snake(&snake)

			rl.DrawText(
				"You died\nPress R to restart",
				WIN_W / 2 - 85,
				WIN_H / 2,
				24,
				rl.LIGHTGRAY,
			)

			if rl.IsKeyPressed(.R) {
				restart_game(&snake, &game_state, &score)
				eat_apple(&apple, &snake, level_grid)
			}
		case .PAUSE:
			draw_background(level_grid, snake)

			draw_apple(apple)
			draw_snake(&snake)

			rl.DrawText("Pause", WIN_W / 2, WIN_H / 2, 24, rl.LIGHTGRAY)

			if rl.IsKeyPressed(.SPACE) {
				game_state = .GAME
				break
			}
		}

		score_text := fmt.ctprintf("Score: %d", score)
		rl.DrawText(score_text, 0, 0, 24, rl.RED)

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}
}

hit_wall :: proc(head: Cell, level_grid: Grid) -> bool {
	if head.pos_x >= level_grid.size_x {
		return true
	} else if head.pos_x < 0 {
		return true
	} else if head.pos_y >= level_grid.size_y {
		return true
	} else if head.pos_y < 0 {
		return true
	}

	return false
}

hit_self :: proc(body: []Cell) -> bool {
	if slice.contains(body[1:], body[0]) {
		return true
	}

	return false
}

eat_apple :: proc(apple: ^Cell, snake: ^Snake, grid: Grid) {
	last_cell: Cell

	if len(snake.body) == 0 {
		last_cell = Cell{15, 15}
	} else {
		last_cell = snake.body[len(snake.body) - 1]
	}

	append(&snake.body, last_cell)

	for {
		apple^ = Cell{rand.int32_range(0, grid.size_x), rand.int32_range(0, grid.size_y)}
		if !slice.contains(snake.body[:], apple^) {break}
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

restart_game :: proc(snake: ^Snake, game_state: ^Game_State, score: ^int) {
	clear(&snake.body)

	for _, i in snake.buffered_direction {
		snake.buffered_direction[i] = .EMPTY
	}

	snake.current_direction = .RIGHT

	score^ = 0

	game_state^ = .GAME
}

update_snake :: proc(snake: ^Snake) {
	current_dir := snake.buffered_direction[0]

	for i := len(snake.body) - 1; i >= 0; i -= 1 {
		if i == 0 {
			if current_dir == .EMPTY {
				current_dir = snake.current_direction
			}

			if current_dir == .UP {
				snake.body[i].pos_y -= 1
			} else if current_dir == .DOWN {
				snake.body[i].pos_y += 1
			} else if current_dir == .RIGHT {
				snake.body[i].pos_x += 1
			} else if current_dir == .LEFT {
				snake.body[i].pos_x -= 1
			}

			break
		}
		snake.body[i] = snake.body[i - 1]
	}

	snake.current_direction = current_dir

	for i := 0; i < len(snake.buffered_direction); i += 1 {
		if i == 2 {
			snake.buffered_direction[i] = .EMPTY
			break
		}
		snake.buffered_direction[i] = snake.buffered_direction[i + 1]
	}

}

snake_movement_direction :: proc(snake: ^Snake) {
	no_empty := true

	for buff in snake.buffered_direction {
		if buff == .EMPTY {
			no_empty = false
			break
		}
	}

	if no_empty {
		return
	}

	tmp_pressed_direction: Direction
	if rl.IsKeyPressed(.UP) {
		if (snake.current_direction == .UP && snake.buffered_direction[0] == .EMPTY) ||
		   (snake.current_direction == .DOWN && snake.buffered_direction[0] == .EMPTY) {return}

		tmp_pressed_direction = .UP
	} else if rl.IsKeyPressed(.DOWN) {
		if (snake.current_direction == .DOWN && snake.buffered_direction[0] == .EMPTY) ||
		   (snake.current_direction == .UP && snake.buffered_direction[0] == .EMPTY) {return}

		tmp_pressed_direction = .DOWN
	} else if rl.IsKeyPressed(.RIGHT) {
		if (snake.current_direction == .RIGHT && snake.buffered_direction[0] == .EMPTY) ||
		   (snake.current_direction == .LEFT && snake.buffered_direction[0] == .EMPTY) {return}

		tmp_pressed_direction = .RIGHT
	} else if rl.IsKeyPressed(.LEFT) {
		if (snake.current_direction == .LEFT && snake.buffered_direction[0] == .EMPTY) ||
		   (snake.current_direction == .RIGHT && snake.buffered_direction[0] == .EMPTY) {return}

		tmp_pressed_direction = .LEFT
	}

	for i := 0; i < len(snake.buffered_direction); i += 1 {
		if snake.buffered_direction[i] != .EMPTY {
			continue
		}

		snake.buffered_direction[i] = tmp_pressed_direction
		break
	}

}

draw_apple :: proc(apple: Cell) {
	rl.DrawRectangle(
		apple.pos_x * CELL_SIZE,
		apple.pos_y * CELL_SIZE,
		CELL_SIZE,
		CELL_SIZE,
		rl.RED,
	)
}

draw_background :: proc(grid: Grid, snake: Snake) {
	for y in 0 ..< grid.size_y {
		for x in 0 ..< grid.size_x {
			c := rl.Color{25, 25, 25, 255} if (x + y) % 2 == 0 else rl.Color{32, 32, 32, 255}
			rl.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, c)
		}
	}
}
