tool
extends Node2D
class_name TetrisShape

enum ShapeConfiguration {
	Z,
	S,
	Line,
	Square,
	T,
	L,
	L_Backwards,
}

export var block_scale = 1.0 setget set_block_scale
export(int, "Z", "S", "Line", "Square", "T", "L", "L_Backwards") var shape_type = ShapeConfiguration.Z setget set_shape_type
export var rotations = 0 setget set_rotations
export var map_position = Vector2.ZERO setget set_map_position

onready var blocks = [get_node("Block1"), get_node("Block2"), get_node("Block3"), get_node("Block4")]
var position_fn: FuncRef

const SPRITE_SIZE = 64

const positions = [
	[Vector2(0, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 1)],
	[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)],
	[Vector2(0, 2), Vector2(0, 1), Vector2(0, 0), Vector2(0, -1)],
	[Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)],
	[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)],
	[Vector2(0, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, 2)],
	[Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 2)],
]

# Called when the node enters the scene tree for the first time.
func _ready():
	update_blocks()

func set_position_fn(fn: FuncRef):
	position_fn = fn

func update_blocks():
	update_block_scale()
	update_block_positions()

func update_block_scale():
	for i in range(blocks.size()):
		blocks[i].set_scale(Vector2(block_scale, block_scale))

func update_block_positions():
	var configured_positions = positions[shape_type]
	var block_size = SPRITE_SIZE * block_scale
	var block_transform = Transform2D()
	block_transform = block_transform.scaled(Vector2(block_size, block_size))
	block_transform = block_transform.rotated(PI/2 * rotations)
	for i in range(blocks.size()):
		blocks[i].set_frame(shape_type)
		blocks[i].position = block_transform.xform(configured_positions[i])

func setget_update():
	if not blocks:
		yield(self, "ready")
	update_blocks()

func set_block_scale(new_block_scale):
	if block_scale == new_block_scale:
		return
	block_scale = new_block_scale
	setget_update()

func set_shape_type(new_shape_type):
	if shape_type == new_shape_type:
		return
	shape_type = new_shape_type
	setget_update()

func set_rotations(new_rotations):
	if rotations == new_rotations:
		return
	rotations = new_rotations
	setget_update()

func set_map_position(new_map_position):
	if map_position == new_map_position:
		return
	map_position = new_map_position
	if position_fn:
		position = position_fn.call_func(map_position)

func block_positions(move: Vector2 = Vector2.ZERO, rotation_change = 0):
	var configured_positions = positions[shape_type]
	var results = []
	var block_transform = Transform2D()
	block_transform = block_transform.rotated(PI/2 * (rotations + rotation_change))
	for p in configured_positions:
		results.push_back((block_transform.xform(p) + map_position + move).round())
	return results
