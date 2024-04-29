extends Node2D

const LOWEST_VOLUME = -80
const DEFAULT_VOLUME = 0

enum Track {
	Sink,
	Click,
	Cancel,
	Hover,
	CardDraw,
	CardDiscard,
	Coins,
	Rumble,
	Paper,
	Move,
	Built,
	Sacrifice,
	Emerge,
	Reinforce
}
enum Ambience { CalmWind }

const TRACKS = {
	Track.Sink: preload("res://audio/sfx/waterexplosion.wav"),
	Track.Click: preload("res://audio/sfx/click2.wav"),
	Track.Cancel: preload("res://audio/sfx/switch10.wav"),
	Track.Hover: preload("res://audio/sfx/click5.wav"),
	Track.CardDraw: preload("res://audio/sfx/cardSlide4.wav"),
	Track.CardDiscard: preload("res://audio/sfx/cardShove2.wav"),
	Track.Coins: preload("res://audio/sfx/chain_03.ogg"),
	Track.Rumble: preload("res://audio/sfx/rumble.wav"),
	Track.Paper: preload("res://audio/sfx/paper.wav"),
	Track.Move: preload("res://audio/sfx/misc_01.ogg"),
	Track.Built: preload("res://audio/sfx/lay_brick.wav"),
	Track.Sacrifice: preload("res://audio/sfx/sacrifice.wav"),
	Track.Emerge: preload("res://audio/sfx/emerge.wav"),
	Track.Reinforce: preload("res://audio/sfx/soldiersshout.wav")
}

const AMBIENCE_TRACKS = {Ambience.CalmWind: preload("res://audio/ambience/wind_calm.wav")}

const RANDOM_PITCH_SCALE = {
	Track.Move: [0.75, 1.25],
	Track.Sink: [0.9, 1.1],
}

const CUSTOM_VOLUME = {
	Track.Sink: -15, Track.Rumble: -5, Track.Move: -15, Track.Built: -10, Track.Sacrifice: -15, Track.Emerge: -15, Track.Reinforce: -15
}

const CUSTOM_AMBIENCE_VOLUME = {Ambience.CalmWind: -45}

# const CUSTOM_POLYPHONY = {Track.Sink: 1}

var players = {}
var ambience_players = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	connect_buttons(get_tree().root)
	get_tree().connect("node_added", Callable(self, "_on_SceneTree_node_added"))
	for key in TRACKS:
		var player = AudioStreamPlayer.new()
		player.stream = TRACKS[key]
		player.max_polyphony = 10  #if key not in CUSTOM_POLYPHONY else CUSTOM_POLYPHONY[key]
		player.bus = "SFX"
		if key in CUSTOM_VOLUME:
			player.volume_db = CUSTOM_VOLUME[key]
		self.add_child(player)
		self.players[key] = player
	for key in AMBIENCE_TRACKS:
		var player = AudioStreamPlayer.new()
		player.stream = AMBIENCE_TRACKS[key]
		player.bus = "Ambience"
		if key in CUSTOM_AMBIENCE_VOLUME:
			player.volume_db = CUSTOM_AMBIENCE_VOLUME[key]
		self.add_child(player)
		self.ambience_players[key] = player


func play_ambience(ambience: Ambience):
	self.ambience_players[ambience].play()


func play(track: Track):
	if track in RANDOM_PITCH_SCALE:
		self.players[track].pitch_scale = randf_range(RANDOM_PITCH_SCALE[track][0], RANDOM_PITCH_SCALE[track][1])
	self.players[track].play()


func disable_track(track: Track):
	self.players[track].volume_db = LOWEST_VOLUME


func enable_track(track: Track):
	self.players[track].volume_db = DEFAULT_VOLUME if track not in CUSTOM_VOLUME else CUSTOM_VOLUME[track]


func _on_SceneTree_node_added(node):
	if node is Button:
		connect_to_button(node)


func _on_Button_pressed():
	self.play(Track.Click)


func on_Button_hovered():
	self.play(Track.Hover)


# recursively connect all buttons
func connect_buttons(root):
	for child in root.get_children():
		if child is BaseButton:
			connect_to_button(child)
		connect_buttons(child)


func connect_to_button(button):
	button.connect("pressed", Callable(self, "_on_Button_pressed"))
	button.connect("mouse_entered", Callable(self, "on_Button_hovered"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
