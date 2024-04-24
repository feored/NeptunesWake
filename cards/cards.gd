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
