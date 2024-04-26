extends RefCounted
class_name Bot

var team = 0

func play_turn(_world):
	pass


func _init(init_team):
	self.team = init_team

func get_regions(world_sim, filter_team):
	return world_sim.regions.values().filter(func(r): return r.team == filter_team).map(func(r): return r.id)

func get_available_regions(world_sim):
	return world_sim.regions.values().filter(func(r): return r.team == self.team and not r.is_used and r.units > 1).map(func(r): return r.id)
