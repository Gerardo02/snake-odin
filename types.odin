package main

Direction :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

Snake :: struct {
	sizeX: i32,
	sizeY: i32,
	posX:  i32,
	posY:  i32,
	dir:   Direction,
}

Grid :: struct {
	sizeX: i32,
	sizeY: i32,
}
