@tool
extends Control

@export var kind: String = "coin"
@export var tint: Color = Color("#f2d080")
@export var spin: bool = false
var phase: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if spin:
		phase += delta * 2.0
		queue_redraw()

func line(points: Array) -> void:
	draw_polyline(PackedVector2Array(points), tint, 1.8, true)

func _draw() -> void:
	var factor := minf(size.x / 28, size.y / 28)
	var offset := (size - Vector2(28, 28) * factor) / 2.0
	draw_set_transform(offset, 0, Vector2.ONE * factor)
	match kind:
		"coin":
			var width := maxf(0.22, absf(cos(phase))) if spin else 1.0
			draw_set_transform(offset + Vector2(14, 14)*factor, 0, Vector2(width, 1)*factor)
			draw_circle(Vector2.ZERO, 11, Color(tint, 0.12))
			draw_arc(Vector2.ZERO, 11, 0, TAU, 40, tint, 2, true)
			draw_arc(Vector2.ZERO, 8, 0, TAU, 40, Color(tint, 0.45), 1, true)
			line([Vector2(3,-5), Vector2(-3,-5), Vector2(-3,0), Vector2(3,0), Vector2(3,5), Vector2(-3,5)])
			line([Vector2(0,-7), Vector2(0,7)])
		"bank":
			line([Vector2(3,9), Vector2(14,3), Vector2(25,9), Vector2(3,9)])
			for x in [7,14,21]: line([Vector2(x,12), Vector2(x,22)])
			line([Vector2(3,25), Vector2(25,25)])
		"home":
			line([Vector2(3,13),Vector2(14,3),Vector2(25,13)])
			line([Vector2(6,11),Vector2(6,25),Vector2(22,25),Vector2(22,11)])
			line([Vector2(11,25),Vector2(11,17),Vector2(17,17),Vector2(17,25)])
		"dice":
			draw_style_box(_box(), Rect2(3,3,22,22))
			for p in [Vector2(8,8),Vector2(20,8),Vector2(14,14),Vector2(8,20),Vector2(20,20)]: draw_circle(p,1.6,tint)
		"lock":
			draw_style_box(_box(),Rect2(5,12,18,13))
			draw_arc(Vector2(14,12),6,PI,TAU,20,tint,2,true)
			line([Vector2(14,17),Vector2(14,21)])
		"transfer", "pay":
			line([Vector2(3,8),Vector2(24,8),Vector2(19,3)])
			line([Vector2(24,8),Vector2(19,13)])
			line([Vector2(25,21),Vector2(4,21),Vector2(9,16)])
			line([Vector2(4,21),Vector2(9,26)])
		"people":
			draw_arc(Vector2(11,8),4,0,TAU,24,tint,1.8,true)
			draw_arc(Vector2(11,23),8,PI,TAU,24,tint,1.8,true)
			draw_arc(Vector2(21,9),3,-PI/2,PI/2,20,tint,1.8,true)
			draw_arc(Vector2(20,23),5,-PI/2,0,12,tint,1.8,true)
		"history":
			line([Vector2(7,3),Vector2(22,3),Vector2(22,25),Vector2(7,25),Vector2(7,3)])
			for y in [9,14,19]: line([Vector2(10,y),Vector2(18,y)])
		"exit":
			line([Vector2(12,3),Vector2(4,3),Vector2(4,25),Vector2(12,25)])
			line([Vector2(10,14),Vector2(25,14),Vector2(20,9)])
			line([Vector2(25,14),Vector2(20,19)])
		"go":
			line([Vector2(3,22),Vector2(3,5),Vector2(24,5),Vector2(24,21),Vector2(11,21)])
			line([Vector2(11,21),Vector2(16,16)])
			line([Vector2(11,21),Vector2(16,26)])
		"sound":
			line([Vector2(3,10),Vector2(8,10),Vector2(14,5),Vector2(14,23),Vector2(8,18),Vector2(3,18),Vector2(3,10)])
			draw_arc(Vector2(14,14),7,-0.9,0.9,20,tint,1.8,true)
			draw_arc(Vector2(14,14),11,-0.9,0.9,20,tint,1.8,true)
		"edit":
			line([Vector2(5,23),Vector2(7,16),Vector2(20,3),Vector2(25,8),Vector2(12,21),Vector2(5,23)])
		"settings":
			for y in [7,14,21]: line([Vector2(3,y),Vector2(25,y)])
			for p in [Vector2(10,7),Vector2(19,14),Vector2(8,21)]:
				draw_circle(p,3,tint)
		"qr":
			for p in [Vector2(3,3),Vector2(17,3),Vector2(3,17)]:
				draw_rect(Rect2(p,Vector2(8,8)),tint,false,1.7)
				draw_rect(Rect2(p+Vector2(3,3),Vector2(2,2)),tint)
			line([Vector2(17,17),Vector2(25,17),Vector2(25,25),Vector2(21,25),Vector2(21,21),Vector2(17,21)])
		_:
			line([Vector2(14,5),Vector2(14,23)])
			line([Vector2(5,14),Vector2(23,14)])

func _box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(tint, 0.08)
	box.border_color = tint
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	return box
