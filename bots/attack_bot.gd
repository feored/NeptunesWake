class_name AttackBot extends Bot

var world_sim : WorldState
var scores : Dictionary

func reinit(world):
	self.world_sim = WorldState.new(world)
	self.update_scores()

func update_scores():
	self.scores = regions_distance_score(self.world_sim)

func can_reinforce_adjacent(region):
	return world_sim.regions[region].team == self.team and not world_sim.regions[region].is_used and get_reinforceable_adjacents(region).size() > 0

func get_reinforceable_adjacents(region):
	return world_sim.adjacent_regions[region].filter(func(r): return world_sim.regions[r].team == self.team \
	and not world_sim.regions[r].is_used)

func try_reinforce():
	Utils.log("Start reinforce phase")
	var reinforceable = self.get_available_regions(world_sim).filter(func (r): return scores[r] > 1 and can_reinforce_adjacent(r))
	if reinforceable.size() == 0:
		Utils.log("No reinforceable regions")
		return null
	var highest_level = reinforceable.map(func (r): return scores[r]).max()
	var from_region = reinforceable.filter(func (r): return scores[r] == highest_level).pick_random()
	var picked_adjacent = get_reinforceable_adjacents(from_region).pick_random()
	Utils.log("Reinforcing phase done")
	return Action.new(Action.Type.Move, {"from": from_region,"to": picked_adjacent, "team": self.team})
	

func play_turn(world):
	self.reinit(world)
	var reinforcement = try_reinforce()
	if reinforcement != null:
		return reinforcement
	for region in self.get_available_regions(world_sim):
		var adjacent_enemies = world_sim.adjacent_regions[region].filter(func (adj): return world_sim.regions[adj].team != self.team)
		if adjacent_enemies.size() > 0:
			var target = adjacent_enemies.pick_random()
			return Action.new(Action.Type.Move, {"from": region, "to": target, "team": self.team})
	## no more moves
	return null

func regions_distance_score(world):
	var new_scores = {}
	for r in world.regions:
		new_scores[r] = -1
	for r in world.regions.keys().filter(func (reg): return world.regions[reg].team != self.team):
		new_scores[r] = 0
	var current_index = 0
	while new_scores.values().filter(func (v): return v == -1).size() > 0:
		var base_score = new_scores.duplicate()
		Utils.log("Current index: " + str(current_index))
		Utils.log(new_scores)
		for r in new_scores.keys().filter(func (reg): return new_scores[reg] == current_index):
			for n in world.adjacent_regions[r]:
				if new_scores[n] == -1:
					new_scores[n] = current_index + 1
		current_index += 1
		if base_score == new_scores:
			break
	print(new_scores)
	return new_scores

