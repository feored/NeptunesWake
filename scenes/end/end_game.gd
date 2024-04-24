extends Node
@onready var score_label = %ScoreLabel
@onready var score_container = %ScoreContainer


func _on_button_pressed():
	SceneTransition.change_scene(SceneTransition.SCENE_MAIN_MENU)


func _ready():
	gen_score()

func gen_score():
	var score_info = Info.run.score()
	var total_score = 0
	for s in score_info.keys():
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var label1 = Label.new()
		label1.text = s
		label1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label1)
		var label2 = Label.new()
		label2.text = str(score_info[s])
		label2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label2)
		total_score += score_info[s]
		score_container.add_child(hbox)
	score_label.text = str(total_score)
