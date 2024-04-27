extends CanvasItem
var coords = []
var visited = []


# Called when the node enters the scene tree for the first time.
func _ready():
	self.custom_minimum_size = Vector2(0, Map.MAP_HEIGHT * 128 * 2 + 128 * 3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _draw():
	for c in coords:
		draw_dashed_line(c[0], c[1], Color.BLACK, 2, 4)
	for v in visited:
		draw_arc(v, 64, 0, 360, 100, Color.RED, 3.0, false)
