extends Node2D

var ShapeResource = preload("res://TetrisShape.tscn")
var ShapeScript = preload("res://TetrisShape.gd")

const SPRITE_SIZE = 64
const BLOCK_SCALE = 0.75
const BLOCK_SIZE = SPRITE_SIZE * BLOCK_SCALE

var shape = ShapeResource.instance()
var shape_preview = ShapeResource.instance()
var score = 0
var start_wait_time

onready var board = $TetrisBoard
onready var timer = $Timer
onready var score_label = $ScoreLabel
onready var paused_label = $CanvasLayer/PausedLabel

func _ready():
	randomize()
	board.scale = Vector2(BLOCK_SCALE, BLOCK_SCALE)
	start_wait_time = timer.wait_time
	shape.set_position_fn(funcref(self, "world_position"))
	shape_preview.position = Vector2(670,200)
	shape_preview.block_scale = BLOCK_SCALE
	shape_preview.shape_type = randi() % ShapeScript.ShapeConfiguration.size()
	restart()
	add_child(shape)
	add_child(shape_preview)

func restart():
	timer.wait_time = start_wait_time
	set_score(0)
	board.clear()
	generate_shape()

func world_position(map_position):
	return board.position + board.map_to_world(map_position) * board.scale + Vector2(BLOCK_SIZE/2, BLOCK_SIZE/2)
	
func generate_shape():
	shape.rotations = 0
	shape.map_position = Vector2(board.width/2,0)
	shape.shape_type = shape_preview.shape_type
	shape.block_scale = BLOCK_SCALE
	shape_preview.shape_type = randi() % ShapeScript.ShapeConfiguration.size()

func all_valid_positions(block_positions):
	for block_position in block_positions:
		if not board.contains(block_position):
			return false
		if block_position.y >= 0 and not board.is_empty_position(block_position):
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
	if Input.is_action_just_pressed("ui_pause"):
		toggle_pause()
	
	if timer.is_paused():
		return
		
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
		
func toggle_pause():
	var paused = !timer.is_paused()
	paused_label.visible = paused
	timer.set_paused(paused)

func set_score(new_score):
	score = new_score
	score_label.text = "Score: %s" % score

func increase_score():
	set_score(score + 1)
	if score % 5 == 0:
		timer.wait_time *= 0.9

func clear_rows():
	for row in range(board.height-1,0,-1):
		while board.is_complete_row(row):
			increase_score()
			board.shift_down(row)

func generated_shape_overlaps() -> bool:
	for block_position in shape.block_positions():
			if block_position.y >= 0 and not board.is_empty_position(block_position):
				return true
	return false

func shape_at_bottom():
	var shape_color = shape.shape_type
	for p in shape.block_positions():
		board.set_cellv(p, shape_color)
	clear_rows()
	generate_shape()
	if generated_shape_overlaps():
		restart()

func _on_Timer_timeout():
	if not try_move(Vector2.DOWN):
		shape_at_bottom()
