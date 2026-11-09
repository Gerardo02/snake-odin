package main

Direction :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

Snake :: struct {
	sizeX:              i32,
	sizeY:              i32,
	posX:               i32,
	posY:               i32,
	ghost_pos_x:        i32,
	ghost_pos_y:        i32,
	len:                i32,
	current_direction:  Direction,
	buffered_direction: Direction,
}

Grid :: struct {
	sizeX: i32,
	sizeY: i32,
}
