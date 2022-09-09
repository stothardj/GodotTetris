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
var shape_preview = ShapeResource.instance()
var score = 0
var start_wait_time

onready var tilemap = $TileMap
onready var timer = $Timer
onready var score_label = $ScoreLabel
onready var paused_label = $CanvasLayer/PausedLabel

func _ready():
	randomize()
	start_wait_time = timer.wait_time
	shape.set_position_fn(funcref(self, "world_position"))
	shape_preview.position = Vector2(685,300)
	shape_preview.block_scale = BLOCK_SCALE
	shape_preview.shape_type = randi() % ShapeScript.ShapeConfiguration.size()
	restart()
	add_child(shape)
	add_child(shape_preview)

func restart():
	timer.wait_time = start_wait_time
	set_score(0)
	initialize_board()
	generate_shape()

func initialize_board():
	for x in range(0, BOARD_WIDTH):
		for y in range(0, BOARD_HEIGHT):
			tilemap.set_cell(x, y, BOARD_BACKGROUND)

func world_position(map_position):
	return tilemap.position + tilemap.map_to_world(map_position) * tilemap.scale + Vector2(BLOCK_SIZE/2, BLOCK_SIZE/2)
	
func generate_shape():
	shape.rotations = 0
	shape.map_position = Vector2(BOARD_WIDTH/2,0)
	shape.shape_type = shape_preview.shape_type
	shape.block_scale = BLOCK_SCALE
	shape_preview.shape_type = randi() % ShapeScript.ShapeConfiguration.size()

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
	
	if Input.is_action_just_pressed("ui_down"):
		try_move(Vector2.DOWN)
		
	if Input.is_action_just_pressed("ui_snap_down"):
		while try_move(Vector2.DOWN):
			# For side-effect of try_move
			pass
		shape_at_bottom()
	
	if Input.is_action_just_pressed("ui_pause"):
		toggle_pause()
		
func toggle_pause():
	var paused = !timer.is_paused()
	paused_label.visible = paused
	timer.set_paused(paused)

func is_complete_row(row: int) -> bool:
	for col in range(0,BOARD_WIDTH-1):
		if empty_position(Vector2(col, row)):
			return false
	return true

func shift_down(row):
	if row == 0:
		for col in range(0,BOARD_WIDTH-1):
			tilemap.set_cell(col, row, BOARD_BACKGROUND)
		return
	for col in range(0,BOARD_WIDTH-1):
		tilemap.set_cell(col, row, tilemap.get_cell(col, row-1))
	shift_down(row-1)

func set_score(new_score):
	score = new_score
	score_label.text = "Score: %s" % score

func increase_score():
	set_score(score + 1)
	if score % 5 == 0:
		timer.wait_time *= 0.9

func clear_rows():
	for row in range(BOARD_HEIGHT-1,0,-1):
		while is_complete_row(row):
			increase_score()
			shift_down(row)

func generated_shape_overlaps() -> bool:
	for block_position in shape.block_positions():
			if block_position.y >= 0 and not empty_position(block_position):
				return true
	return false

func shape_at_bottom():
	var shape_color = shape.shape_type
	for p in shape.block_positions():
		tilemap.set_cellv(p, shape_color)
	clear_rows()
	generate_shape()
	if generated_shape_overlaps():
		restart()

func _on_Timer_timeout():
	if not try_move(Vector2.DOWN):
		shape_at_bottom()
