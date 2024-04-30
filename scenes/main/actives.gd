extends RefCounted
class_name Actives

static func val(e):
	return e.computed_value if e.computed_value != null else e.value

static func random_discard(effect, _world, _game):
	return Action.new(Action.Type.RandomDiscard, {'value': val(effect)})

static func draw(effect, _world, _game):
	return Action.new(Action.Type.Draw, {'value': val(effect)})

static func faith(effect, _world, game):
	var expression = Expression.new()
	expression.parse(val(effect), game.current_player.resources.keys())
	var result = expression.execute(game.current_player.resources.values())
	return Action.new(Action.Type.Faith, {'value': result})

static func sink_random_self_tiles(effect, world, game):
	var own_tiles = world.tiles.values().filter(func(t): return t.data.team == game.current_player.team)
	var nb = min(val(effect), own_tiles.size())
	var selected = []
	own_tiles.shuffle()
	for i in range(nb):
		selected.push_back(own_tiles.pop_front().data.coords)
	return Action.new(Action.Type.Sink, {'value': selected})

static func sink_random_tiles(effect, world, _game):
	var all_tiles = world.tiles.values()
	var nb = min(val(effect), all_tiles.size())
	var selected = []
	all_tiles.shuffle()
	for i in range(nb):
		selected.push_back(all_tiles.pop_front().data.coords)
	return Action.new(Action.Type.Sink, {'value': selected})

static func emerge_random_tiles(effect, world, game):
	var computed_nb = val(effect) + game.current_player.compute("flat_emerge_bonus")
	var all_tiles = world.tiles.values()
	var emergeable = []
	for tile in all_tiles:
		for coords in Utils.get_surrounding_cells(tile.data.coords):
			if !world.tiles.has(coords):
				emergeable.push_back(coords)
	var nb = min(computed_nb, all_tiles.size())
	emergeable.shuffle()
	return Action.new(Action.Type.Emerge, {'value': emergeable.slice(0, nb).map(func(c): return [c])})
	
static func treason(effect, world, game):
	var nb_treason = val(effect)
	var own_regions = world.regions.values().filter(func(r): return r.data.team == game.current_player.team)
	own_regions.shuffle()
	var regions_treasoned = []
	for i in range(nb_treason):
		var region = own_regions.pop_front()
		var new_team = game.get_random_enemy().team
		regions_treasoned.push_back({"region": region.data.id, "new_team": new_team})
	return Action.new(Action.Type.Treason, {'value': regions_treasoned})


static func renewal(_effect, world, game):
	var own_regions = world.regions.values().filter(func(r): return r.data.team == game.current_player.team).map(func(r): return r.data.id)
	return Action.new(Action.Type.Renewal, {'value': own_regions})
	
static func mark_random(effect, world, _game):
	var nb = val(effect)
	var all_tiles = world.tiles.values()
	var marked = []
	all_tiles.shuffle()
	for i in range(nb):
		var tile = all_tiles.pop_front()
		marked.push_back(tile.data.coords)
	return Action.new(Action.Type.Mark, {'value': marked})

static func apply(effect, world, game):
	return Callable(Actives, effect.target).call(effect, world, game) 
