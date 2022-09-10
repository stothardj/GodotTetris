extends TileMap

export var width = 100
export var height = 100

const BOARD_BACKGROUND = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func clear() -> void:
	for x in range(0, width):
		for y in range(0, height):
			set_cell(x, y, BOARD_BACKGROUND)

func is_empty_position(map_position: Vector2) -> bool:
	return get_cellv(map_position) == BOARD_BACKGROUND

func contains(map_position: Vector2) -> bool:
	if map_position.x < 0 or map_position.x >= width:
		return false
	return map_position.y < height

func shift_down(row) -> void:
	if row == 0:
		for col in range(0,width-1):
			set_cell(col, row, BOARD_BACKGROUND)
		return
	for col in range(0,width-1):
		set_cell(col, row, get_cell(col, row-1))
	shift_down(row-1)

func is_complete_row(row: int) -> bool:
	for col in range(0,width-1):
		if is_empty_position(Vector2(col, row)):
			return false
	return true
