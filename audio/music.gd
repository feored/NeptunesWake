extends AudioStreamPlayer

const MIN_VOLUME = -80
const MIN_CROSSFADE_VOLUME = -50
const CROSSFADE_TIME = 1
const DEFAULT_VOLUME = 0.0

## Tracks
enum Track { Menu, World1, World2, World3, World4, World5, World6 }
const BGM_TRACKS = {
	Track.Menu: preload("res://audio/music/suno_2.mp3"),
	Track.World1: preload("res://audio/music/suno_1.mp3"),
	Track.World2: preload("res://audio/music/suno_2.mp3"),
	Track.World3: preload("res://audio/music/suno_3.mp3"),
	Track.World4: preload("res://audio/music/suno_4.mp3"),
	Track.World5: preload("res://audio/music/suno_5.mp3"),
	Track.World6: preload("res://audio/music/suno_6.mp3")
}

const WORLD_TRACKS = [
	Track.World1, Track.World2, Track.World3, Track.World4, Track.World5, Track.World6
]

@onready var timer : Timer = Timer.new()
var world_index = -1


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	



func play_track(track: Track):
	## crossfade
	if self.stream != null:
		var tween = self.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "volume_db", MIN_CROSSFADE_VOLUME, CROSSFADE_TIME)
		tween.tween_callback(_play.bind(track))
		tween.tween_property(self, "volume_db", DEFAULT_VOLUME, CROSSFADE_TIME)
	else:
		_play(track)


func play_world():
	world_index = (world_index + 1) % WORLD_TRACKS.size() 
	var next_track = WORLD_TRACKS[world_index]
	var length = BGM_TRACKS[next_track].get_length() - CROSSFADE_TIME
	if self.timer != null:
		self.timer.stop()
		self.timer.queue_free()
	self.timer = Timer.new()
	self.add_child(timer)
	timer.timeout.connect(play_world)
	timer.start(length)
	play_track(next_track)


func _play(track: Track):
	Utils.log("Now playing track: " + str(track))
	self.stream = BGM_TRACKS[track]
	self.play()
