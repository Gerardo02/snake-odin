package main

Direction :: enum {
	EMPTY,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

Snake :: struct {
	body:               [dynamic]Cell,
	current_direction:  Direction,
	buffered_direction: [3]Direction,
}

Cell :: struct {
	pos_x: i32,
	pos_y: i32,
}

Grid :: struct {
	size_x: i32,
	size_y: i32,
}
