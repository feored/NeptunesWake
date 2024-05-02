extends Control
signal event_over

@onready var card_container = %CardContainer
const card_view_prefab = preload("res://cards/card_view/card_view.tscn")
var picked = false

var card_views = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(3):
		var card = Cards.generate(Info.run.get_level())
		var cv = card_view_prefab.instantiate()
		cv.card = card
		cv.is_static = true
		cv.picked.connect(Callable(self, "card_picked"))
		card_container.add_child(cv)


func card_picked(cv):
	if picked:
		return
	picked = true
	for other_cv in card_views:
		if other_cv != cv:
			other_cv.flip_in_place()
	await Utils.wait(0.5)
	Info.run.deck.push_back(cv.card)
	over()

func over():
	event_over.emit()
