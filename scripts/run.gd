extends RefCounted
class_name Run

const STARTING_DECK = ["Sacrifice", "Flood", "Creation", "CretanArchers", "Barracks", "Seal", "Flood", ]

var deck : Array[Card] = []
var map : Map
var coords : Vector2i = Map.START
var gold : int = 0


func _init():
	map = Map.new()
	for card_id in STARTING_DECK:
		var card  = Cards.get_card(card_id)
		self.deck.push_back(card)
	# for i in range(50):
	# 	var rand_level = max(1, int((Utils.rng.randf_range(1.0, 10.5)**2)/10))
	# 	Utils.log("rand_level: %d" % rand_level)
	# 	self.deck.push_back(Cards.generate(rand_level))

func get_open_nodes():
	if self.coords == Map.START:
		return map.get_entrances()
	else:
		return map.map[self.coords].next

func get_floor():
	return self.coords.x

func get_level():
	return self.coords.x + 1

func is_beaten():
	return self.map.boss.visited

func score():
	var total_score = {
		"Wealth": self.gold,
		"Modifiers": 0,
	}
	for m in self.map.map.values():
		if m.visited:
			total_score["Modifiers"] += m.level * 10
	return total_score

