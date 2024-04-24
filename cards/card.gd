extends RefCounted
class_name Card

var id: String
var name: String
var effects: Array
var cost: int
var icon: Texture
var exhaust: bool = false


func _init(
	init_id: String,
	init_name: String,
	init_effects: Array,
	init_cost: int,
	init_icon: Texture = null,
	init_exhaust: bool = false
):
	self.id = init_id
	self.name = init_name
	self.effects = init_effects
	self.cost = init_cost
	self.icon = init_icon
	self.exhaust = init_exhaust


static func from_json(card_json: Dictionary):
	var all_effects = []
	for e in card_json["effects"]:
		all_effects.push_back(Effect.new(e.id, e.tier))
	return Card.new(
		card_json["id"],
		card_json["name"],
		all_effects,
		card_json["cost"],
		load(card_json["icon"]) if card_json.has("icon") else null,
		card_json.has("exhaust") and card_json["exhaust"]
	)


func copy():
	return Card.new(
		self.id, self.name, self.effects.duplicate(), self.cost, self.icon, self.exhaust
	)
