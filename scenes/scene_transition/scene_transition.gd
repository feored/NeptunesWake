extends CanvasLayer
@onready var texture_rect = $Texture

const SCENE_MAIN_GAME = "res://scenes/main/main.tscn"
const SCENE_MAIN_MENU = "res://scenes/main_menu/main_menu.tscn"
const SCENE_MAP_GENERATOR = "res://scenes/map_generator/map_generator.tscn"
const SCENE_MAP_EDITOR = "res://scenes/map_editor/map_editor.tscn"
const SCENE_CAMPAIGN = "res://scenes/campaign/campaign.tscn"
const SCENE_OVERWORLD = "res://scenes/overworld/overworld.tscn"
const SCENE_END = "res://scenes/end/end_game.tscn"
const SCENE_REWARD = "res://scenes/run_reward/run_reward.tscn"

@onready var animation_player = $AnimationPlayer

func _ready():
	self.texture_rect.hide()

func change_scene(target: String) -> void:
	#animation_player.play("fade_out")
	#await animation_player.animation_finished
	await self.set_screenshot()
	self.fade_in()
	self.fade_out()
	get_tree().change_scene_to_file(target)
	

func fade_in():
	self.texture_rect.show()
	self.texture_rect.modulate = Color.WHITE

func fade_out():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self.texture_rect, "modulate", Color.TRANSPARENT, 0.25)
	tween.tween_callback(self.texture_rect.hide)

func set_screenshot():
	var capture = get_viewport().get_texture().get_image()
	texture_rect.texture = ImageTexture.create_from_image(capture)
