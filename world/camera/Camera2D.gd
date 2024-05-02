extends Camera2D


var active = true

@onready var viewport_size = get_viewport().content_scale_size
@onready var camera_center = -viewport_size/2


@onready var LIMIT_X_NEGATIVE = camera_center.x - viewport_size.x * 0.5
@onready var LIMIT_X_POSITIVE = camera_center.x + viewport_size.x * 0.5
@onready var LIMIT_Y_NEGATIVE = camera_center.y - viewport_size.y * 0.5
@onready var LIMIT_Y_POSITIVE = camera_center.y + viewport_size.y * 0.5

const CAMERA_SPEED = 10
const CAMERA_SPEED_SKIP = 50

var zoom_anim_time = 0.1
var zoom_factor = 0.05
var min_zoom = Vector2(1, 1)
var max_zoom = Vector2(4, 4)
var panning = false
var pan_speed = 0.1

func _unhandled_input(event):
	if Settings.input_locked:
		return
	if event.is_action_released('zoom_in'):
		zoom_camera(zoom_factor)
	if event.is_action_released('zoom_out'):
		zoom_camera(-zoom_factor)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			self.panning = event.pressed
	elif event is InputEventMouseMotion and self.panning:
		var new_pos = self.position - event.relative / self.zoom
		self.position = new_pos.clamp(Vector2(LIMIT_X_NEGATIVE, LIMIT_Y_NEGATIVE), Vector2(LIMIT_X_POSITIVE, LIMIT_Y_POSITIVE))

func zoom_camera(zf):
	var prev_zoom = zoom
	var new_zoom = clamp(zoom + ( zoom * zf), min_zoom, max_zoom)
	var new_pos = self.position + (Vector2(self.viewport_size)/prev_zoom - Vector2(self.viewport_size)/new_zoom)/2 
	#var tween = self.create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN).set_parallel()
	#tween.tween_property(self, "position", new_pos, zoom_anim_time)
	#tween.tween_property(self, "zoom", new_zoom, zoom_anim_time)
	self.zoom = new_zoom
	self.position = new_pos

func _ready():
	if self.position == Vector2.ZERO:
		self.position = camera_center
	self.position_smoothing_enabled = false
	self.position_smoothing_speed = CAMERA_SPEED

func move_instant(target):
	if not active:
		return
	self.panning = false
	self.position = target - Vector2(self.viewport_size)/self.zoom/2

func skip(val: bool):
	if self.position_smoothing_enabled:
		self.position_smoothing_speed = CAMERA_SPEED_SKIP if val else CAMERA_SPEED


func move_smoothed(target, precision = 1):
	if not active:
		return
	if !Settings.get_setting(Settings.Setting.AutoCameraFocus):
		return
	self.panning = false
	self.position_smoothing_enabled = true
	self.position =  target - Vector2(self.viewport_size)/self.zoom/2
	self.position_smoothing_speed = CAMERA_SPEED_SKIP if Settings.skipping else CAMERA_SPEED
	var arrived_center = target
	while abs((arrived_center - get_screen_center_position()).length_squared()) > precision:
		await Utils.wait(0.1)
	self.position_smoothing_enabled = false
