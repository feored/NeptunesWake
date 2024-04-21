extends Camera2D


var active = true

@onready var viewport_size = get_viewport().content_scale_size
@onready var camera_center = -viewport_size/2


@onready var LIMIT_X_NEGATIVE = camera_center.x - viewport_size.x * 0.5
@onready var LIMIT_X_POSITIVE = camera_center.x + viewport_size.x * 0.5
@onready var LIMIT_Y_NEGATIVE = camera_center.y - viewport_size.y * 0.5 * 16/9
@onready var LIMIT_Y_POSITIVE = camera_center.y + viewport_size.y * 0.5 * 16/9

const CAMERA_SPEED = 10
const CAMERA_SPEED_SKIP = 50

var zoom_speed = 0.1
var min_zoom = Vector2(1, 1)
var max_zoom = Vector2(4, 4)
var panning = false
var pan_speed = 0.1

func _input(event):
	if Settings.input_locked:
		return
	if event.is_action_released('zoom_in'):
		zoom_camera(zoom_speed, event.position)
	if event.is_action_released('zoom_out'):
		zoom_camera(-zoom_speed, event.position)


func _unhandled_input(event):
	if Settings.input_locked:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			self.panning = event.pressed
	elif event is InputEventMouseMotion and self.panning:
		self.position -= event.relative / zoom

func zoom_camera(zoom_factor, mouse_position):
	var prev_zoom = zoom
	var new_zoom = clamp(zoom + ( zoom * zoom_factor), min_zoom, max_zoom)
	var new_pos = self.position - ((viewport_size * 0.5) - mouse_position ) * (zoom - prev_zoom)
	var tween = self.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_parallel()
	tween.tween_property(self, "zoom", new_zoom, zoom_speed)
	tween.tween_property(self, "position", new_pos, zoom_speed)
	#self.zoom = 
	#self.position -= ((viewport_size * 0.5) - mouse_position ) * (zoom - prev_zoom)
	


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
	self.position = target - Vector2(self.viewport_size/2)
	self.position_smoothing_speed = CAMERA_SPEED_SKIP if Settings.skipping else CAMERA_SPEED
	var arrived_center = target
	while abs((arrived_center - get_screen_center_position()).length_squared()) > precision:
		await Utils.wait(0.1)
	self.position_smoothing_enabled = false
