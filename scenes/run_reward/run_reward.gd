extends Control

const card_view_prefab = preload("res://cards/card_view/card_view.tscn")

@onready var gold_label = %DrachmeLabel
@onready var cards_container = %CardsContainer
@onready var rewards = %Rewards
@onready var loss = %Loss
@onready var score_label = %ScoreLabel
@onready var score_container = %ScoreContainer
var reward_gold : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Info.lost:
		self.rewards.show()
		self.loss.hide()
		self.reward_gold = Info.run.get_floor() * Utils.rng.randi_range(8,12)
		self.gold_label.text = str(self.reward_gold)
		for i in range(3):
			var card = Cards.all_cards().pick_random()
			var cv = card_view_prefab.instantiate()
			cv.card = Cards.get_card(card)
			cv.is_static = true
			cv.picked.connect(Callable(self, "pick_card"))
			cards_container.add_child(cv)
			cv.flip()
			cv.flip_in_place()
			await Utils.wait(Constants.DECK_LONG_TIMER)
	else:
		self.rewards.hide()
		self.loss.show()
		self.gen_score()
	

func init(init_win : bool):
	self.win = init_win

func pick_card(cv):
	Info.run.deck.push_back(cv.card)
	next()

func next():
	Info.run.gold += self.reward_gold
	await SceneTransition.change_scene(SceneTransition.SCENE_OVERWORLD)

func lose():
	await SceneTransition.change_scene(SceneTransition.SCENE_MAIN_MENU)

func _on_continue_btn_pressed():
	next()

func _on_continue_loss_btn_pressed():
	lose()

func gen_score():
	var score_info = Info.run.score()
	var total_score = 0
	for s in score_info.keys():
		var hbox = HBoxContainer.new()
		var label1 = Label.new()
		label1.text = s
		hbox.add_child(label1)
		var label2 = Label.new()
		label2.text = str(score_info[s])
		hbox.add_child(label2)
		total_score += score_info[s]
		score_container.add_child(hbox)
	score_label.text = str(total_score)
