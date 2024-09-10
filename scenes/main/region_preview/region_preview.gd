extends PanelContainer

var preview_line_prefab = preload("res://scenes/main/region_preview/region_preview_line.tscn")

@onready var preview_lines : VBoxContainer = %PreviewLines
@onready var total_label : Label = %TotalQty
@onready var total_power : Label = %TotalPower

var current_region_id = Constants.NULL_REGION

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func setup(region: Region) -> void:
	self.cleanup()
	self.current_region_id = region.data.id
	var total_attack_min = 0
	var total_attack_max = 0
	for troop in region.data.troops:
		if troop.count > 0:
			var preview_line = self.preview_line_prefab.instantiate()
			preview_line.init(troop)
			self.preview_lines.add_child(preview_line)
			total_attack_min += Troops.DATA[troop.type].attack.min * troop.count
			total_attack_max += Troops.DATA[troop.type].attack.max * troop.count
	var total_troops = region.data.troops.total()
	self.total_label.text = str(total_troops)
	self.total_power.text = str(total_attack_min) + "-" + str(total_attack_max)
	self.show()

func cleanup() -> void:
	self.current_region_id = Constants.NULL_REGION
	for child in self.preview_lines.get_children():
		child.queue_free()
	self.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
