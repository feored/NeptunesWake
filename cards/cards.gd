extends Node

const CARD_DATA_PATH = "res://cards/cards.json"
const EFFECT_DATA_PATHS = [
	"res://cards/effects/data/powers.json",
	"res://cards/effects/data/actives.json",
	"res://cards/effects/data/resources.json"
]

var effects: Array = []
var cards: Dictionary


func _ready():
	self.cards = read_into(CARD_DATA_PATH)
	for path in EFFECT_DATA_PATHS:
		self.effects += read_into(path)
	Utils.log("Loaded " + str(self.effects.size()) + " effects")


func read_into(path):
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())


func get_card(id: String):
	return Card.from_json(self.cards[id])


func get_effect_tree(id: String):
	return self.effects.filter(func(e): return e.id == id)[0]

func all_cards():
	return self.cards.keys()

func generate(target_level = 3):
	var available_effects = []
	for e in self.effects:
		var ok = true
		for t in e.tiers:
			if int(t.cost) < 0:
				ok = false
				break
		if ok:
			available_effects.push_back(e)
	var random_effects = []
	var cost = 0
	var level = 0
	while level < target_level:
		var picked_effect = available_effects.pick_random()
		var picked_tier = Utils.rng.randi() % picked_effect.tiers.size()
		var new_effect = Effect.new(picked_effect.id, picked_tier + 1)
		
		cost += int(picked_effect.tiers[picked_tier].cost)
		available_effects.erase(picked_effect)
		if new_effect.type == Effect.Type.Power:
			for e in available_effects:
				for t in e.tiers:
					if t.type == "power":
						available_effects.erase(e)
			random_effects.push_front(new_effect)
		else:
			random_effects.push_back(new_effect)
		level += new_effect.level
	var card = Card.new(
		"custom",
		"Random",
		random_effects,
		cost,
		load("res://cards/images/questionmark2.png")
	)
	Utils.log("Generated card: " + card.to_string())

	return card
