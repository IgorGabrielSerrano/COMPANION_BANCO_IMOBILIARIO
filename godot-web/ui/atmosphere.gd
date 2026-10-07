extends Control

var clock: float = 0.0
var particles: Array = []
var reduced: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func celebrate(origin: Vector2) -> void:
	if reduced: return
	for i in range(18):
		particles.append({"position": origin, "velocity": Vector2(randf_range(-145,145),randf_range(-320,-100)), "life": 1.2, "phase": randf()*TAU})

func _process(delta: float) -> void:
	clock += delta
	for p in particles:
		p.position += p.velocity * delta
		p.velocity.y += 360 * delta
		p.life -= delta
		p.phase += delta * 8
	particles = particles.filter(func(p): return p.life > 0)
	if not reduced or not particles.is_empty(): queue_redraw()

func _draw() -> void:
	for x in range(0,int(size.x),44):
		for y in range(0,int(size.y),44):
			draw_circle(Vector2(x,y),1,Color(0.42,0.58,0.62,0.075))
	for i in range(5):
		var center := Vector2(size.x*(0.1+i*0.21), size.y*(0.12+i*0.17)+sin(clock*0.35+i)*8)
		draw_arc(center,28,0,TAU,40,Color(0.85,0.71,0.4,0.025),1,true)
	for p in particles:
		var alpha: float = minf(1,p.life*2)
		var width: float = maxf(1,absf(cos(p.phase))*5)
		draw_set_transform(p.position,0,Vector2(width/5,1))
		draw_circle(Vector2.ZERO,5,Color(0.96,0.78,0.35,alpha))
		draw_arc(Vector2.ZERO,3,0,TAU,12,Color(0.4,0.27,0.05,alpha),1,true)
		draw_set_transform(Vector2.ZERO)
