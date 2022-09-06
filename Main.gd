extends Node2D

var ShapeResource = preload("res://TetrisShape.tscn")
var ShapeScript = preload("res://TetrisShape.gd")

const SPRITE_SIZE = 64
const BLOCK_SCALE = 0.5
const BLOCK_SIZE = SPRITE_SIZE * BLOCK_SCALE
const BOARD_WIDTH = 15
const BOARD_HEIGHT = 25
const BOARD_BACKGROUND = 7

var shape = ShapeResource.instance()

onready var tilemap = $TileMap

func _ready():
	randomize()
	shape.set_position_fn(funcref(self, "world_position"))
	initialize_board()
	generate_shape()
	add_child(shape)

func initialize_board():
	for x in range(0, BOARD_WIDTH):
		for y in range(0, BOARD_HEIGHT):
			tilemap.set_cell(x, y, BOARD_BACKGROUND)

func world_position(map_position):
	return tilemap.position + tilemap.map_to_world(map_position) * tilemap.scale + Vector2(BLOCK_SIZE/2, BLOCK_SIZE/2)
	
func generate_shape():
	shape.rotations = 0
	shape.map_position = Vector2(BOARD_WIDTH/2,0)
	shape.shape_type = randi() % ShapeScript.ShapeConfiguration.size()
	shape.block_scale = BLOCK_SCALE

func in_board(map_position: Vector2):
	if map_position.x < 0 or map_position.x >= BOARD_WIDTH:
		return false
	return map_position.y < BOARD_HEIGHT

func empty_position(map_position: Vector2):
	return tilemap.get_cellv(map_position) == BOARD_BACKGROUND

func all_valid_positions(block_positions):
	for block_position in block_positions:
		if not in_board(block_position):
			return false
		if block_position.y >= 0 and not empty_position(block_position):
			return false
	return true

func try_move(move: Vector2) -> bool:
	if not all_valid_positions(shape.block_positions(move)):
		return false
	shape.map_position += move
	return true

func try_rotate(rotation_change: int) -> bool:
	if not all_valid_positions(shape.block_positions(Vector2.ZERO, rotation_change)):
		return false
	shape.rotations += rotation_change
	return true

func _process(_delta):
	var move_dir = int(Input.is_action_just_pressed("ui_right")) - int(Input.is_action_just_pressed("ui_left"))
	if move_dir < 0:
		try_move(Vector2.LEFT)
	elif move_dir > 0:
		try_move(Vector2.RIGHT)
		
	var rotate_dir = int(Input.is_action_just_pressed("ui_rotate_right")) - int(Input.is_action_just_pressed("ui_rotate_left"))
	if rotate_dir < 0:
		try_rotate(-1)
	elif rotate_dir > 0:
		try_rotate(1)


func _on_Timer_timeout():
	if not try_move(Vector2.DOWN):
		var shape_color = shape.shape_type
		for p in shape.block_positions():
			tilemap.set_cellv(p, shape_color)
		generate_shape()

