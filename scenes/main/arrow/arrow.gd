extends Node2D
signal canceled

const BLOCKS_NUM = 100
const COLOR_VALID = Color(0, 1, 0)
const COLOR_INVALID = Color(1, 0, 0)
const block_prefab = preload("res://scenes/main/arrow/block.tscn")

var validate_function: Callable
var try_function: Callable

var world: Node
var effect: Effect
var start_point = Vector2(1000, 1000)
var middle_point = Vector2(960, 540)
var blocks = []
var mouse_item: Variant
var last_tile: Vector2i


# Called when the node enters the scene tree for the first time.
func _ready():
	init()
	self.middle_point.x = self.start_point.x
	for i in range(BLOCKS_NUM):
		var block = block_prefab.instantiate()
		add_child(block)
		blocks.append(block)
	organize(middle_point)


func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r


func color_blocks(color):
	for block in blocks:
		block.modulate = color
	self.mouse_item.modulate = color


func organize(mouse_pos):
	for i in range(BLOCKS_NUM):
		var t = i / float(BLOCKS_NUM)
		var pos = _quadratic_bezier(start_point, middle_point, mouse_pos, t)
		self.blocks[i].position = pos
		if i > 0:
			self.blocks[i].rotation = ((self.blocks[i].position - self.blocks[i - 1].position).angle())
	self.mouse_item.position = mouse_pos


func _input(event):
	if event is InputEventMouseMotion:
		var current_tile = self.world.global_pos_to_coords(event.position)
		if current_tile != last_tile:
			last_tile = current_tile
			organize(self.world.coords_to_pos_zoom(current_tile))
			color_blocks(
				(
					COLOR_VALID
					if validate_function.call(event.position, self.effect)
					else COLOR_INVALID
				)
			)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			canceled.emit()
			self.queue_free()
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_function.call(event.position, self.effect)
			self.queue_free()
	if self.mouse_item != null:
		self.mouse_item.scale = self.world.camera.zoom


func set_icon(icon):
	self.mouse_item = Sprite2D.new()
	self.mouse_item.texture = load(icon)
	# self.current.reinforcements = new_reinforcements + self.game.current_player.compute("flat_reinforce_bonus")
	self.set_mouse_item()


func set_mouse_item():
	self.add_child(self.mouse_item)
	self.mouse_item.global_position = get_viewport().get_mouse_position()


func init():
	match self.effect.target:
		"reinforcements":
			self.set_icon("res://assets/icons/Plus.png")
		"sacrifice":
			self.set_icon("res://assets/icons/skull.png")
		"build":
			var b = Constants.BUILDING_ENUM[self.effect.value]
			self.set_icon(Constants.BUILDINGS[b].texture)
		"sink":
			self.mouse_item = Shape.new()
			self.mouse_item.init_with_json_coords(self.effect.computed_value)
			self.set_mouse_item()
		"emerge":
			self.mouse_item = Shape.new()
			self.mouse_item.init_with_json_coords(self.effect.computed_value)
			self.set_mouse_item()
