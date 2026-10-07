extends Control

var matrix: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(0,270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if matrix.is_empty(): return
	var count := matrix.size()
	var cell := floorf(minf(size.x,size.y) / (count+8))
	var width := cell * (count+8)
	var origin := (size-Vector2(width,width))/2
	draw_rect(Rect2(origin,Vector2(width,width)),Color.WHITE)
	for row in range(count):
		for col in range(count):
			if matrix[row][col]: draw_rect(Rect2(origin+Vector2((col+4)*cell,(row+4)*cell),Vector2(cell,cell)),Color.BLACK)
