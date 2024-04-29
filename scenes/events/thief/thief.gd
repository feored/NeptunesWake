extends Control
signal event_over

@onready var deck_view = %DeckView
@onready var pick_card_button = %PickCardButton
var picked : bool = false

const COST = 50


func _ready():
	pick_card_button.disabled = Info.run.gold < COST

func _on_pick_card_button_pressed():
	deck_view.card_picked.connect(Callable(self, "card_picked"))
	deck_view.init(Info.run.deck)
	deck_view.show()


func card_picked(card):
	if picked:
		return
	picked = true
	deck_view.hide()
	Info.run.deck.push_back(card.copy())
	Info.run.gold -= COST
	Sfx.play(Sfx.Track.Coins)
	over()


func _on_skip_button_pressed():
	over()

func over():
	event_over.emit()
