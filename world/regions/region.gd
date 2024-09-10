extends Node2D
class_name Region

signal tile_added
signal tile_deleted
signal region_deleted

var tilePrefab = preload("res://world/tiles/tile.tscn")
var regionLabelPrefab = preload("res://world/regions/region_label.tscn")

var coords_to_pos: Callable
var get_contiguous_tilesets: Callable

class RegionData:
	var id: int
	var team: int
	var tiles: Array
	# var n_tiles: int
	var troops: Troops
	var is_used: bool

	func _init():
		self.id = Constants.NULL_REGION
		self.team = Constants.NULL_TEAM
		self.tiles = []
		self.troops = Troops.new()
		# self.n_tiles = 0
		self.is_used = false

	func save():
		return {"id": self.id, "team": self.team, "tiles": self.tiles, "troops": self.troops, "is_used": self.is_used}
	
	func _to_string():
		return "Region %s, team %s, %s tiles, %s troops, %s" % [str(self.id), str(self.team), str(self.tiles.size()), str(self.troops.total()), "used" if self.is_used else "unused"]
	
	func clone():
		var new_data = RegionData.new()
		new_data.id = self.id
		new_data.team = self.team
		new_data.tiles = self.tiles.duplicate()
		# new_data.n_tiles = self.n_tiles
		new_data.troops = self.troops
		new_data.is_used = self.is_used
		return new_data


var data: RegionData = RegionData.new()
var tile_objs: Dictionary = {}
var label = null

func save():
	var base = self.data.save()
	base.tiles.clear()
	for tile in self.tile_objs.values():
		base.tiles.append(tile.data.save())
	return base


func init_from_save(saved_region):
	self.data.id = saved_region.id
	self.data.team = saved_region.team
	if typeof(saved_region.units) is int:
		self.data.troops.thetes = saved_region.units
	else:
		self.data.troops = saved_region.units
	self.data.is_used = saved_region.is_used if saved_region.has("is_used") else false
	for tile in saved_region.tiles:
		spawn_cell(Vector2i(tile["x"], tile["y"]), tile["team"], tile)


func _init(init_id):
	self.data.id = init_id
	self.label = regionLabelPrefab.instantiate()
	self.add_child(self.label)
	self.label.z_index = 100

func _ready():
	self.name = StringName("Region " + str(self.data.id))


func delete():
	for tile in self.tile_objs.values():
		tile_deleted.emit(tile.data.coords)
		tile.queue_free()
	self.tile_objs.clear()
	self.data.tiles.clear()
	region_deleted.emit(self.data.id)
	if label != null:
		self.label.queue_free()
	self.queue_free()


func clear():
	# for t in self.tile_objs.values():
	# 	self.remove_child(t)
	self.tile_objs.clear()
	self.data.tiles.clear()



func sacrifice():
	self.data.troops = Troops.new()
	self.set_team(Constants.NULL_TEAM)
	self.update()


func update_label():
	
	var text = ""
	for troop in self.data.troops:
		if troop.count > 0:
			text += str(troop.count) + "[img]" + Troops.DATA[troop.type]["icon"] + "[/img] "
	if text == "":
		text = "0"
	if Constants.DEBUG_REGION:
		text += "(" + str(self.data.id) + ")"
	self.label.set_text(text)
	self.label.position = self.coords_to_pos.call(self.center_tile()) - self.label.size / 2  ## size of the label

func update():
	#Utils.log("Start update", self.data.id)
	#Utils.log("Tiles:", self.data.tiles)
	if self.data.tiles.size() < 1:
		self.delete()
		return
	self.update_label()
	self.update_borders()


func set_team(init_team):
	self.data.team = init_team
	for tile in self.tile_objs.values():
		tile.set_team(self.data.team)


func add_tile(tileObj, should_reparent = false):
	tileObj.data.region = self.data.id
	tileObj.deleted.connect(delete_tile)
	var coords = tileObj.data.coords
	self.data.tiles.append(coords)
	# self.data.n_tiles+=1
	self.tile_objs[coords] = tileObj
	if should_reparent:
		tileObj.reparent(self)
	else:
		self.add_child(tileObj)
	self.update()


func remove_tile(coords, delete_child = false, should_update = true):
	if coords not in self.data.tiles:
		Utils.log("Error: tile %s not in region" % str(coords))
		return
	if delete_child:
		self.remove_child(self.tile_objs[coords])
	self.data.tiles.erase(coords)
	self.tile_objs.erase(coords)
	# self.data.n_tiles-=1
	if should_update:
		self.update()
	


func random_in_region():
	return self.data.tiles[randi() % self.data.tiles.size()]


func generate_units(units_per_tile):
	self.data.troops.thetes += self.data.tiles.size() * units_per_tile
	for tile in self.tile_objs.values():
		if tile.data.building == Constants.Building.Barracks:
			self.data.troops.thetes += Constants.BARRACKS_UNITS_PER_TURN
	self.update()

func surviving_troops(starting_troops, damage):
	var total_troops = starting_troops.clone()
	for troop in total_troops:
		if troop.count > 0:
			if troop.count * Troops.DATA[troop.type]["defense"] >= damage:
				total_troops.set_unit(troop.type, troop.count - ceil(damage /Troops.DATA[troop.type]["defense"]))
				break
			else:
				damage -= troop.count * Troops.DATA[troop.type]["defense"]
				total_troops.set_unit(troop.type, 0)
	return total_troops

func attack(attackers, team):
	var total_attack_value = 0
	for troop in attackers:
		Utils.log("Troop: %s, count: %s" % [str(troop.type), str(troop.count)])
		total_attack_value += troop.count * Utils.rng.randf_range(Troops.DATA[troop.type]["attack"]["min"], Troops.DATA[troop.type]["attack"]["max"])
	
	total_attack_value = round(total_attack_value)

	var total_defense_value = 0
	for troop in self.data.troops:
		total_defense_value += troop.count * Troops.DATA[troop.type]["defense"]

	var captured = false
	Utils.log("##############Attack value: %s, Defense value: %s" % [str(total_attack_value), str(total_defense_value)])
	if total_attack_value > total_defense_value:
		## we lose
		self.data.troops = surviving_troops(attackers, total_defense_value)
		if self.data.troops.total() > 0:
			captured = true
			self.set_team(team)
			Effects.trigger(Effect.Trigger.RegionGained)
	else:
		## we hold on
		self.data.troops = surviving_troops(self.data.troops, total_attack_value)
	self.update()
	return [total_attack_value, total_defense_value, captured]

func reinforce_card(num_reinforcements):
	self.data.troops.psilos += num_reinforcements
	self.update()

func reinforce(new_troops):
	self.data.troops.add_troops(new_troops)
	self.update()

func center_tile():
	var total = Vector2i(0, 0)
	for tile_obj in self.tile_objs.values():
		total += tile_obj.data.coords
	var avg = Vector2(
		float(total.x) / self.tile_objs.size(), float(total.y) / self.tile_objs.size()
	)
	var closest_tile = self.tile_objs.values()[0]
	var closest_distance = avg.distance_squared_to(closest_tile.data.coords)
	for t in self.tile_objs.values():
		var distance = avg.distance_squared_to(t.data.coords)
		if distance < closest_distance:
			closest_tile = t
			closest_distance = distance
	return closest_tile.data.coords


func set_selected(to_show: bool):
	for t in self.tile_objs.values():
		t.set_selected(to_show)


func set_used(is_used: bool):
	self.data.is_used = is_used
	for t in self.tile_objs.values():
		t.set_barred(is_used)


func spawn_cell(coords, team, save_data = {}):
	if self.data.tiles.has(coords):
		Utils.log("Error: cell already exists at " + str(coords))
		return
	var new_tile = tilePrefab.instantiate()
	new_tile.init_cell(coords, self.coords_to_pos.call(coords), team, self.data.id)
	new_tile.deleted.connect(delete_tile)
	self.data.tiles.append(coords)
	self.add_child(new_tile)
	if Constants.DEBUG_POSITION:
		var new_label = Label.new()
		new_label.text = str(coords)
		new_label.set_theme(load("res://assets/theme.tres"))
		new_label.position = -Vector2(12, 12)
		new_tile.add_child(new_label)
	self.tile_objs[coords] = new_tile
	if save_data.size() > 0:
		new_tile.init_from_save(save_data)
	tile_added.emit(new_tile)
	return new_tile


func delete_tile(coords):
	#var avg_pop = self.data.units / self.data.tiles.size()
	self.data.tiles.erase(coords)
	self.tile_objs.erase(coords)
	#self.data.units -= avg_pop
	tile_deleted.emit(coords)
	self.update()


func sink_tile(coords):
	self.tile_objs[coords].sink()
	self.tile_objs.erase(coords)


func update_borders():
	for coords in self.data.tiles:
		for neighbor_direction in Constants.NEIGHBORS:
			var neighbor = Utils.get_neighbor_cell(coords, neighbor_direction)
			if self.data.tiles.has(neighbor):
				if self.tile_objs[coords].data.region != self.tile_objs[neighbor].data.region:
					self.tile_objs[coords].set_single_border(neighbor_direction, true)
				else:
					self.tile_objs[coords].set_single_border(neighbor_direction, false)
			else:
				self.tile_objs[coords].set_single_border(neighbor_direction, true)
