package main

Direction :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

Snake :: struct {
	cell_size:          i32,
	pos_x:              i32,
	pos_y:              i32,
	body:               [dynamic]Cell,
	len:                i32,
	current_direction:  Direction,
	buffered_direction: Direction,
}

Cell :: struct {
	pos_x: i32,
	pos_y: i32,
}

Grid :: struct {
	sizeX: i32,
	sizeY: i32,
}
