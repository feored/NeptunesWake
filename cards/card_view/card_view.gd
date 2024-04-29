extends Control
class_name CardView

signal picked(card : CardView)

enum State { Idle, Hovered, Selected, DrawnOrDiscarded}

const COLOR_INVALID = Color(1, 0.5, 0.5)
var COLOR_VALID = Color.hex(0x47a9ff)
const BASE_Z_INDEX = 0
const HOVER_Z_INDEX = 1

@onready var card_icon : TextureRect = %PowerIcon
@onready var card_name : Label = %PowerName
@onready var card_cost : Label = %PowerCost
@onready var front : Control = %Front
@onready var back : Control = %Back
@onready var exhaust_label : Label = %ExhaustLabel
@onready var effect_container : Control = %EffectContainer

const effect_prefab = preload("res://cards/effects/effect_view.tscn")

var compute_effect : Callable

var buyable: bool = true
var tweens = []
var card : Card
var state : State = State.Idle
var card_ready : bool = false
var base_position : Vector2
var is_static : bool = false
var is_being_used : bool = false

func gen_tooltip(e):
	Utils.log("Generating tooltip for " + str(e))
	var tooltip = e.tooltip
	if "_VALUE_" in tooltip:
		tooltip = tooltip.replace("_VALUE_", str(e.value))
	if "_COMPUTE_" in tooltip:
		tooltip = tooltip.replace("_COMPUTE_", str(e.value if e.computed_value == null else e.computed_value))
	if "_VALUEARRAY_" in tooltip:
		tooltip = tooltip.replace("_VALUEARRAY_", str(e.value.size()))
	if "_COMPUTEARRAY_" in tooltip:
		tooltip = tooltip.replace("_COMPUTEARRAY_", str(e.value.size() if e.computed_value == null else e.computed_value.size()))
	return tooltip

func check_finished():
	for t in self.tweens:
		if t.is_valid() and t.is_running():
			return
	self.clear_tweens()
	

func set_buyable(b : bool):
	self.buyable = b
	self.card_cost.modulate = COLOR_VALID if b else COLOR_INVALID

func clear_tweens():
	for tween in self.tweens:
		tween.kill()
	self.tweens.clear()
	self.card_ready = true

func animate(new_pos, new_rotation, new_z_index):
	self.card_ready = false
	if self.tweens.size() > 0:
		clear_tweens()

	var tween = self.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(self, "position", new_pos, Constants.DECK_SHORT_TIMER)
	tween.tween_property(self, "rotation_degrees", new_rotation, Constants.DECK_SHORT_TIMER)
	tween.tween_property(self, "scale", Vector2(1,1), Constants.DECK_SHORT_TIMER)
	tween.tween_property(self, "z_index", new_z_index, Constants.DECK_SHORT_TIMER)

	self.tweens = [tween]

	for t in self.tweens:
		t.connect("finished", Callable(self, "check_finished"))
	# Utils.log("Animating card to " + str(new_pos) + " " + str(new_rotation) + " " + str(new_z_index))

func move(new_pos, call_when_finished = null):
	## used for draw/discard
	if self.tweens.size() > 0:
		clear_tweens()
	var tween_pos = self.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN).set_parallel()
	tween_pos.tween_property(self, "position", new_pos, Constants.DECK_LONG_TIMER)
	if call_when_finished != null:
		tween_pos.chain().tween_callback(call_when_finished)
	tween_pos.chain().tween_callback(func(): self.state = State.Idle; card_ready = true)
	tweens = [tween_pos]

	# if to_flip:
	# 	var tween_flip = self.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	# 	tween_flip.tween_property(self, "scale", Vector2(0, 1), Constants.DECK_LONG_TIMER/2.0)
	# 	tween_flip.tween_callback(flip)
	# 	tween_flip.tween_property(self, "scale", Vector2(1, 1), Constants.DECK_LONG_TIMER/2.0)
	# 	tweens.push_back(tween_flip)

	for t in self.tweens:
		t.connect("finished", Callable(self, "check_finished"))

func flip_in_place():
	var tween_flip = self.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).chain()
	tween_flip.tween_property(self, "scale:x", 0.0, Constants.DECK_LONG_TIMER/2.0)
	tween_flip.tween_callback(flip)
	tween_flip.tween_property(self, "scale:x", 1.0, Constants.DECK_LONG_TIMER/2.0)
	tweens.push_back(tween_flip)
	for t in self.tweens:
		t.connect("finished", Callable(self, "check_finished"))

func discard(pos):
	self.state = State.DrawnOrDiscarded
	self.move(pos, Callable(self, "queue_free"))

func flip():
	if self.front.visible:
		self.front.hide()
		self.back.show()
	else:
		self.front.show()
		self.back.hide()

func mouse_inside():
	return Rect2(Vector2(), self.size).has_point(get_local_mouse_position())

# Called when the node enters the scene tree for the first time.
func _ready():
	self.config()

func config():
	if self.card == null:
		return
	self.card_name.text = self.card.name
	if self.card.icon != null:
		self.card_icon.texture = self.card.icon
	
	self.card_cost.text = str(self.card.cost)
	self.exhaust_label.visible = self.card.exhaust
	for effect in self.card.effects:
		# var effect_view = effect_prefab.instantiate()
		# effect_view.init(effect)
		# self.effect_container.add_child(effect_view)
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = self.gen_tooltip(effect)
		self.effect_container.add_child(label)


	if not self.is_static:
		self.mouse_entered.connect(Callable(self, "_on_mouse_entered"))
		self.mouse_exited.connect(Callable(self, "_on_mouse_exited"))

func init(c : Card):
	self.card = c
	
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and self.buyable:
			self.picked.emit(self)


func disconnect_picked():
	for c in self.picked.get_connections():
		self.picked.disconnect(c.callable)

func highlight(to_highlight):
	self.self_modulate = Color(0.5, 1, 0.5) if to_highlight else Color(1, 1, 1)

func _on_mouse_entered():
	if self.state == State.Idle and self.card_ready:
		self.animate(Vector2(self.position.x, self.position.y - 50), 0, HOVER_Z_INDEX)
		self.state = CardView.State.Hovered

func _on_mouse_exited():
	if self.is_being_used:
		return
	## Mouse actually exited
	unhover()

func unhover():
	if self.state == State.Hovered:
		if not self.card_ready:
			self.clear_tweens()
		self.animate(base_position, 0, BASE_Z_INDEX)
		self.state = CardView.State.Idle

func compute_effects():
	for effect in self.card.effects.filter(func(e): return e.type != Effect.Type.Resource):
		effect.computed_value = self.compute_effect.call(effect)
	if self.is_node_ready():
		regen_tooltips()

func regen_tooltips():
	for child in self.effect_container.get_children():
		child.queue_free()
	for effect in self.card.effects:
		# var effect_view = effect_prefab.instantiate()
		# effect_view.init(effect)
		# self.effect_container.add_child(effect_view)
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = self.gen_tooltip(effect)
		self.effect_container.add_child(label)
