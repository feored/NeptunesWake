extends Button

signal show_tooltip(tooltip)
signal hide_tooltip

const EVENT_ICON = preload("res://scenes/overworld/map_view/event_icon.png")
const MAP_ICON = preload("res://scenes/overworld/map_view/map_icon_blank.png")

const mod_list_prefab = preload("res://scenes/overworld/mod_view/mod_list.tscn")

@onready var label = $Label

var island = null


func init(i):
	self.island = i


func update_view():
	if self.island == null:
		return
	if self.island.location == Map.Location.Event:
		self.icon = EVENT_ICON
	else:
		self.icon = MAP_ICON
		self.label.text = str(island.level)


# Called when the node enters the scene tree for the first time.
func _ready():
	self.mouse_entered.connect(Callable(self, "_on_mouse_entered"))
	self.mouse_exited.connect(Callable(self, "_on_mouse_exited"))
	update_view()


func _on_mouse_exited():
	if Rect2(Vector2(), self.size).has_point(get_local_mouse_position()):
		return
	self.hide_tooltip.emit()


func _on_mouse_entered():
	if self.island == null:
		return
	if self.island.location == Map.Location.Event:
		var label = Label.new()
		label.text = "Random Event"
		label.set("theme_override_colors/font_color", Color.BLACK)
		self.show_tooltip.emit(label, self.position + self.size / 2)
	elif self.island.mods.size() == 0:
		var label = Label.new()
		label.set("theme_override_colors/font_color", Color.BLACK)
		label.text = "No Mods"
		self.show_tooltip.emit(label, self.position + self.size / 2)
	else:
		var mod_list = mod_list_prefab.instantiate()
		mod_list.mouse_exited.connect(Callable(self, "_on_mouse_exited"))
		mod_list.init(self.island.mods)
		self.show_tooltip.emit(mod_list, self.position + self.size / 2)
