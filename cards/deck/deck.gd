extends Control


const CARD_SIZE = Vector2(250, 350)
const CARD_SPACING : float = CARD_SIZE.x
@onready var viewport_size = get_viewport().content_scale_size
@onready var CENTER = Vector2(viewport_size.x / 2.0 - CARD_SIZE.x/2.0, viewport_size.y - CARD_SIZE.y)
@onready var DRAW_POS = Vector2(-CARD_SIZE.x, viewport_size.y - CARD_SIZE.y)
@onready var DISCARD_POS = Vector2(viewport_size.x + CARD_SIZE.x, viewport_size.y - CARD_SIZE.y)

const card_prefab = preload("res://cards/card_view/card_view.tscn")

@onready var draw_pile_button : Button = %DrawPileButton
@onready var discard_pile_button : Button = %DiscardPileButton
@onready var deck_view = %DeckView
@onready var draw_pile_deck : Control

var card_played : Callable
var compute_effect : Callable

var draw_pile = []
var discard_pile = []
var hand = []
var exhausted = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for c in Info.run.deck:
		self.draw_pile.push_back(c)
	self.draw_pile.shuffle()
	Effects.triggered.connect(compute_all_effects)

func compute_all_effects():
	for c in self.hand:
		c.compute_effects()

func draw_multiple(amount: int):
	for i in range(amount):
		await draw()
		Effects.trigger(Effect.Trigger.CardDrawn)

func discard_to_draw():
	for c in self.discard_pile:
		self.draw_pile.push_back(c)
	self.discard_pile.clear()
	self.draw_pile.shuffle()

func draw():
	if self.draw_pile.size() == 0:
		discard_to_draw()
		if self.draw_pile.size() == 0:
			return
	var cardView = card_prefab.instantiate()
	cardView.state = CardView.State.DrawnOrDiscarded
	cardView.card = self.draw_pile.pop_front()
	cardView.compute_effect = self.compute_effect
	cardView.compute_effects()
	self.add_card(cardView)
	await Utils.wait(Constants.DECK_SHORT_TIMER)
	cardView.card_ready = true
	update_display()
	

func add_card(cv):
	cv.disconnect_picked()
	cv.picked.connect(func(cv): card_played.call(cv))
	add_child(cv)
	cv.position = DRAW_POS
	self.hand.append(cv)
	place_all()
	update_display()

func place_all():
	for i in range(self.hand.size()):
		var card_placement = place_card(self.hand[i])
		self.hand[i].base_position = card_placement[0]
		self.hand[i].move(card_placement[0])
		#self.hand[i].rotation_degrees = card_placement[1]

func discard(cardView):
	var card_id = self.hand.find(cardView)
	Utils.log("Discarding card: ", card_id)
	if card_id != -1:
		self.hand.remove_at(card_id)
		self.discard_pile.push_back(cardView.card)
		await cardView.discard(DISCARD_POS)
		Effects.trigger(Effect.Trigger.CardDiscarded)
	self.place_all()
	update_display()

func exhaust(cardView):
	var card_id = self.hand.find(cardView)
	if card_id != -1:
		self.hand.remove_at(card_id)
		self.exhausted.push_back(cardView.card)
		cardView.queue_free()
		self.place_all()
		Effects.trigger(Effect.Trigger.CardExhausted)
	await Utils.wait(Constants.DECK_LONG_TIMER)
	update_display()

func discard_random(amount: int):
	var drawn_copy = self.hand.duplicate()
	drawn_copy.shuffle()
	var to_del = min(drawn_copy.size(), amount)
	for i in range(to_del):
		await self.discard(drawn_copy[i])

func discard_all():
	while self.hand.size() > 0:
		await discard(self.hand[0])
	self.hand.clear()


func place_card(card):
	var id = self.hand.find(card)
	var total = self.hand.size()
	var middle = floor(total / 2.0)
	var num = id - middle
	var spacing = CARD_SPACING if hand.size() <= 3 else (CARD_SPACING - 12.5 * (hand.size() - 3))
	var x = CENTER.x + num * spacing
	var to_sample
	if total <= 1:
		to_sample = 00
	else:
		to_sample = id / (total - 1.0)
	var y = CENTER.y #- POSITION_CURVE.sample(to_sample)
	# print("x: ", x, "y: ", y, "to_sample: ", to_sample)
	return [Vector2(x, y), 0]#2 * num]
	

func update_faith(new_faith):
	for card in self.hand:
		card.set_buyable(card.card.cost <= new_faith)


func update_display():
	self.draw_pile_button.text = str(self.draw_pile.size()) + " - Draw"
	self.discard_pile_button.text = str(self.discard_pile.size()) + " - Discard"

func _on_discard_pile_button_pressed():
	self.deck_view.init(self.discard_pile)
	self.deck_view.show()

func _on_draw_pile_button_pressed():
	self.deck_view.init(self.draw_pile)
	self.deck_view.show()
