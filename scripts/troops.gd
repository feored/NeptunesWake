class_name Troops
enum Type { Thete, Psilos, Hoplite, Hippeus }


class Troop:
	var type: Type
	var count: int


var thetes: int
var psilos: int
var hoplites: int
var hippeis: int

var current: Type = Type.Thete

const DATA = {
	Type.Thete:
	{
		"id": Type.Thete,
		"name": "Thete",
		"attack": {"min": 2, "max": 10},
		"defense": 1,
		# "texture": preload("res://assets/icons/Thete.png"),
		"tooltip": "The Thetes were the lowest social class of citizens in Ancient Greece.",
	},
	Type.Psilos:
	{
		"id": Type.Psilos,
		"name": "Psilos",
		"attack": {"min": 1, "max": 3},
		"defense": 2,
		# "texture": preload("res://assets/icons/Psilos.png"),
		"tooltip":
		"The Psiloi were the light infantry of the Ancient Greek armies. They usually acted as skirmishers, were equipped with ranged weapons and did not wear armor.",
	},
	Type.Hoplite:
	{
		"id": Type.Hoplite,
		"name": "Hoplite",
		"attack": {"min": 1, "max": 3},
		"defense": 3,
		# "texture": preload("res://assets/icons/Hoplite.png"),
		"tooltip": "The Hoplites were the heavily armed infantry of the Ancient Greek armies.",
	},
	Type.Hippeus:
	{
		"id": Type.Hippeus,
		"name": "Hippeus",
		"attack": {"min": 3, "max": 5},
		"defense": 4,
		# "texture": preload("res://assets/icons/Hippeus.png"),
		"tooltip": "The Hippeis were the cavalry of the Ancient Greek armies.",
	},
}


func _iter_init(_arg):
	current = Type.Thete
	return true


func _iter_next(_arg):
	current = (current as int + 1) as Type
	return (current as int) < (Type.Hippeus as int)


func _iter_get(_arg):
	var troop = Troop.new()
	troop.type = current
	troop.count = self.get_unit(current)
	return troop


func _init() -> void:
	self.thetes = 0
	self.psilos = 0
	self.hoplites = 0
	self.hippeis = 0


func add_troops(troops: Troops) -> void:
	self.thetes += troops.thetes
	self.psilos += troops.psilos
	self.hoplites += troops.hoplites
	self.hippeis += troops.hippeis


func move_units() -> Troops:
	var new_troops = Troops.new()
	var lowest_troop = 0
	for troop in self:
		if troop.count > 0:
			lowest_troop = troop.type
			break
	for troop in self:
		if troop.type == lowest_troop:
			new_troops.set_unit(troop.type, troop.count - 1)
			self.set_unit(troop.type, 1)
		else:
			new_troops.set_unit(troop.type, troop.count)
			self.set_unit(troop.type, 0)
	return new_troops


func total() -> int:
	return self.thetes + self.psilos + self.hoplites + self.hippeis


func get_unit(unit: Type):
	match unit:
		Type.Thete:
			return self.thetes
		Type.Psilos:
			return self.psilos
		Type.Hoplite:
			return self.hoplites
		Type.Hippeus:
			return self.hippeis


func set_unit(unit: Type, val: int) -> void:
	match unit:
		Type.Thete:
			self.thetes = val
		Type.Psilos:
			self.psilos = val
		Type.Hoplite:
			self.hoplites = val
		Type.Hippeus:
			self.hippeis = val


func set_all(val: int) -> void:
	self.thetes = val
	self.psilos = val
	self.hoplites = val
	self.hippeis = val


func clone() -> Troops:
	var new_troops = Troops.new()
	new_troops.thetes = self.thetes
	new_troops.psilos = self.psilos
	new_troops.hoplites = self.hoplites
	new_troops.hippeis = self.hippeis
	return new_troops
