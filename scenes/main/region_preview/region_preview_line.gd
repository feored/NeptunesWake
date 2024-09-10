extends HBoxContainer
@onready var Qty : Label = $Qty
@onready var Icon : TextureRect = $Icon
@onready var Power : Label = $Power

var troop : Troops.Troop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.Qty.text = str(troop.count)
	self.Icon.texture = load(Troops.DATA[troop.type].icon)
	self.Power.text = str(Troops.DATA[troop.type].attack.min) + "-" + str(Troops.DATA[troop.type].attack.max)

func init(troop: Troops.Troop) -> void:
	self.troop = troop
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
