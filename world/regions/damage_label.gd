extends Label
var damage : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = str(damage)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 2)
	tween.parallel().tween_property(self, "position:y", self.position.y - 20, 2)
	tween.tween_callback(func (): self.queue_free())


func init(init_damage):
	self.damage = init_damage
