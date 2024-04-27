extends Node

const active_effect_prefab = preload("res://scenes/main/active_effects/active_effect.tscn")
var player = null
var active_effects = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	Effects.triggered.connect(Callable(self, "_on_effect_list_changed"))


func _on_effect_list_changed():
	var effects = Effects.effects[self.player].filter(func (e): return e.type == Effect.Type.Resource)
	for effect in active_effects.keys():
		if effect not in effects:
			active_effects[effect].queue_free()
			active_effects.erase(effect)
	for e in effects:
		if e not in active_effects:
			var active_effect = active_effect_prefab.instantiate()
			active_effects[e] = active_effect
			active_effect.tooltip_text = e.tooltip
			self.add_child(active_effect)
