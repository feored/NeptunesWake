extends Node2D

const shape_prefab = preload("res://world/tiles/highlight/shape.tscn")
const mod_list_prefab = preload("res://scenes/overworld/mod_view/mod_list.tscn")
const arrow_prefab = preload("res://scenes/main/arrow/arrow.tscn")

@onready var world = $"World"
@onready var messenger = %Message
@onready var endTurnButton = %TurnButton
@onready var fastForwardButton = %FastForwardButton
@onready var deck = %Deck
@onready var faith_label = %FaithLabel
@onready var mods_scroll_container = %ModsScrollContainer
@onready var active_effects = %ActiveEffects

var used_card = null

enum MouseState {
	None,
	Aim,
	Move
}

var mouse_state = MouseState.None

var mouse_item : Node = null
var selected_region = null

var cards_to_pick = 1

var game : Game

var over : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Settings.input_locked = false
	Settings.skipping = false
	self.world.init(Callable(self.messenger, "set_message"))
	Music.play_track(Music.Track.World)
	Sfx.enable_track(Sfx.Track.Boom)

	self.game = Game.new(Info.current_map.teams.map(func(t): return int(t)))
	Effects.init(self.game.players, Callable(self.game, "get_current_player"))
	Effects.apply_active.connect(apply_active)
	self.active_effects.player = self.game.human
	self.add_mods(Info.current_mods)
	self.load_map(Info.current_map.regions)
	
	var mod_list = mod_list_prefab.instantiate()
	mod_list.init(Info.current_mods)
	self.mods_scroll_container.add_child(mod_list)
	
	self.game.started = true
	Utils.log("Formerly ", self.world.map_to_local(closest_player_tile_coords()))
	Utils.log("Moving to pos: ", self.world.coords_to_pos(closest_player_tile_coords()))
	self.world.camera.move_instant(self.world.coords_to_pos(closest_player_tile_coords()))
	self.deck.card_played = use_card
	self.deck.compute_effect = compute_effect
	
	prepare_turn()

func apply_active(effect):
	var action = Actives.apply(effect, self.world, self.game)
	await self.apply_action(action)

func add_mod_effect(e):
	if e.target == MapMods.Target.World:
		var instanced_effect = Effect.new(e.effect.id, e.effect.tier)
		Effects.add_global(instanced_effect)
		return
	var players_to_apply = []
	if e.target == MapMods.Target.Human:
		players_to_apply = [self.game.human]
	elif e.target == MapMods.Target.Enemies:
		players_to_apply = self.game.players.filter(func(p): return p.team != self.game.human.team)
	elif e.target == MapMods.Target.All:
		players_to_apply = self.game.players
	for player in players_to_apply:
		var instanced_effect = Effect.new(e.effect.id, e.effect.tier)
		Effects.add(instanced_effect, player)

func add_mods(mods):
	for mod_key in mods:
		var mod = MapMods.mods[mod_key]
		for effect in mod.effects:
			add_mod_effect(effect)
		

func clear_mouse_state():
	if self.mouse_item != null:
		self.mouse_item.queue_free()
	self.mouse_item = null
	clear_selected_region()
	self.mouse_state = MouseState.None
	if self.used_card != null:
		self.used_card.is_being_used = false
		self.used_card.highlight(false)
		self.used_card.unhover()
		self.used_card = null	


func validate_mark(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	return world.tiles.has(coords_hovered)

func try_mark(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	var region_hovered = world.tiles[coords_hovered].data.region
	var all_region_tiles = world.regions[region_hovered].data.tiles
	var action = Action.new(Action.Type.Mark, {"value": all_region_tiles})
	await apply_action(action)
	if self.used_card != null:
		card_used(self.used_card)
	self.mouse_state = MouseState.None

func validate_emerge(mouse_pos, effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	var s = Shape.new()
	s.init_with_json_coords(effect.computed_value)
	return s.emergeable(coords_hovered, self.world.tiles.keys())

func try_emerge(mouse_pos, effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	var s = Shape.new()
	s.init_with_json_coords(effect.computed_value)
	if s.emergeable(coords_hovered, self.world.tiles.keys()):
		var action = Action.new(Action.Type.Emerge, {'value': [s.adjusted_shape_coords(coords_hovered)]})
		await apply_action(action)
		if self.used_card != null:
			card_used(self.used_card)
	else:
		messenger.set_message("You can only raise land from the sea, my lord.")
	self.mouse_state = MouseState.None


func validate_sink(_mouse_pos, _effect):
	# var coords_hovered = world.global_pos_to_coords(mouse_pos)
	# var s = Shape.new()
	# s.init_with_json_coords(effect.computed_value)
	# return s.placeable(coords_hovered, self.world.tiles.keys())
	return true

func try_sink(mouse_pos, effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	var s = Shape.new()
	s.init_with_json_coords(effect.computed_value)
	var tiles_to_sink = s.adjusted_shape_coords(coords_hovered).filter(func(t): return self.world.tiles.has(t))
	if tiles_to_sink.size() > 0:
		var action = Action.new(Action.Type.Sink, {'value' : tiles_to_sink})
		await apply_action(action)
	if self.used_card != null:
		card_used(self.used_card)
	self.mouse_state = MouseState.None

func validate_building(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	return world.tiles.has(coords_hovered)\
		and world.tiles[coords_hovered].data.team == self.game.human.team\
		and world.tiles[coords_hovered].data.building == Constants.Building.None

func try_building(mouse_pos, effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	if !world.tiles.has(coords_hovered):
		messenger.set_message("You can only build on land, my lord.")
		self.mouse_state = MouseState.None
		return
	if self.world.tiles[coords_hovered].data.team != self.game.human.team:
		messenger.set_message("You can only build on territory you own, my lord.")
		self.mouse_state = MouseState.None
		return
	if self.world.tiles[coords_hovered].data.building != Constants.Building.None:
		messenger.set_message("There is already a construction there, my lord.")
		self.mouse_state = MouseState.None
		return
	var action = Action.new(Action.Type.Build, {"coords": coords_hovered, "building": Constants.BUILDING_ENUM[effect.value]})
	await self.apply_action(action)
	card_used(self.used_card)
	self.mouse_state = MouseState.None
	
func validate_reinforcements(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	if self.world.tiles.has(coords_hovered):
		if self.world.tiles[coords_hovered].data.team == self.game.human.team or (
				self.world.tiles[coords_hovered].data.team == Constants.NULL_TEAM and self.game.human.compute("reinforce_neutral") != 0):
				return true
	return false

func try_reinforcements(mouse_pos, effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	if !world.tiles.has(coords_hovered):
			messenger.set_message("You can't send reinforcements to the sea, my lord.")
			clear_mouse_state()
			return
	if self.world.tiles[coords_hovered].data.team != self.game.human.team:
		if self.world.tiles[coords_hovered].data.team == Constants.NULL_TEAM:
			if self.game.human.compute("reinforce_neutral") == 0:
				messenger.set_message("You cannot send reinforcements to a neutral region!")
				clear_mouse_state()
				return
		else:
			messenger.set_message("You cannot send reinforcements to the enemy!")
			clear_mouse_state()
			return
	var region_reinforced = self.world.tiles[coords_hovered].data.region
	var action = Action.new(Action.Type.Reinforce, {"region": region_reinforced, "value": effect.computed_value})
	await self.apply_action(action)
	if self.used_card != null:
		card_used(self.used_card)
	self.mouse_state = MouseState.None

func validate_sacrifice(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	if world.tiles.has(coords_hovered) and self.world.tiles[coords_hovered].data.team == self.game.human.team:
		return true
	return false

func try_sacrifice(mouse_pos, _effect):
	var coords_hovered = world.global_pos_to_coords(mouse_pos)
	if !world.tiles.has(coords_hovered):
		messenger.set_message("There are no people to sacrifice here, my lord.")
		clear_mouse_state()
		return
	if self.world.tiles[coords_hovered].data.team != self.game.human.team:
		messenger.set_message("You cannot sacrifice the people of a territory you don't own, my lord.")
		clear_mouse_state()
		return
	var region_sacrificed = self.world.tiles[coords_hovered].data.region
	var action = Action.new(Action.Type.Sacrifice, {"region": region_sacrificed})
	await self.apply_action(action)
	if self.used_card != null:
		card_used(self.used_card)
	self.mouse_state = MouseState.None
			
		

func _unhandled_input(event):
	if event.is_action_pressed("skip"):
		fast_forward(true)
	elif event.is_action_released("skip"):
		fast_forward(false)
	elif event is InputEventMouse:
		if Settings.input_locked or !self.game.started:
			return
		if self.mouse_state == MouseState.Aim:
			return
		## Right click to cancel
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			clear_mouse_state()
		var coords_clicked = world.global_pos_to_coords(event.position)
		if world.tiles.has(coords_clicked):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if mouse_state != MouseState.Move:
					clear_mouse_state()
				handle_move(self.world.get_tile_region(coords_clicked))

func lock_controls(val : bool):
	self.endTurnButton.disabled = val

func _on_turn_button_pressed():
	await self.deck.discard_all()
	
	lock_controls(true)
	clear_mouse_state()
	self.world.clear_regions_used()
	Settings.input_locked = true

	await play_global_turn()
	
	

	var tile_camera_move = closest_player_tile_coords()
	if tile_camera_move != Constants.NULL_COORDS:
		await self.world.camera.move_smoothed(self.world.map_to_local(tile_camera_move), 5)

	## Faith generation
	self.prepare_turn()
	Settings.input_locked = false
	lock_controls(false)

func _on_cards_selected(cards):
	for card in cards:
		card.disconnect_picked()
		card.picked.connect(func(): use_card(card))
		self.deck.add_card(card)
		self.deck.update_faith(self.game.human.resources.faith)
	Settings.input_locked = false
	lock_controls(false)

func calc_shape(init_coords, bonus = 0):
	var s = Shape.new()
	s.init_with_json_coords(init_coords)
	s.add_bonus(int(bonus))
	return s.coords.keys()

func calc_random_shape(total):
	return calc_shape([], total)

func compute_effect(effect, global = false):
	var computed = func(res):
		var player = self.game.current_player
		if global:
			player = self.game.global
		return player.compute(res)
	match effect.target:
		"reinforcements":
			return effect.value + computed.call("flat_reinforce_bonus")
		"sacrifice":
			return effect.value
		"emerge":
			return calc_shape(effect.value, computed.call("flat_emerge_bonus"))
		"sink":
			return calc_shape(effect.value, computed.call("flat_sink_bonus"))
		"build":
			return effect.value
		"reinforcements":
			return effect.value
		"random_discard":
			return effect.value 
		"draw":
			return effect.value 
		"faith":
			return effect.value 
		"sink_random_self_tiles":
			return calc_random_shape(effect.value + computed.call("flat_sink_bonus"))
		"sink_random_tiles":
			return calc_random_shape(effect.value + computed.call("flat_sink_bonus"))
		"emerge_random_tiles":
			return calc_random_shape(effect.value + computed.call("flat_emerge_bonus"))
		"treason":
			return effect.value 
		"renewal":
			return effect.value
		"mark":
			return effect.value
		"mark_random":
			return calc_random_shape(effect.value)
		_:
			Utils.log("Unknown active effect: %s" % effect.target)
			return 0
			


func create_arrow(cv):
	cv.is_being_used = true
	Utils.log("Starting aiming")
	self.mouse_state = MouseState.Aim
	var new_canvas_layer = CanvasLayer.new()
	var arrow = arrow_prefab.instantiate()
	arrow.effect = cv.card.effects.filter(func(e): return e.type == Effect.Type.Power)[0]
	arrow.canceled.connect(func(): clear_mouse_state())
	arrow.start_point = Vector2(cv.position.x + cv.size.x / 2, cv.position.y)
	arrow.world = self.world
	match arrow.effect.target:
		"reinforcements":
			arrow.validate_function = validate_reinforcements
			arrow.try_function = try_reinforcements
		"sacrifice":
			arrow.validate_function = validate_sacrifice
			arrow.try_function = try_sacrifice
		"build":
			arrow.validate_function = validate_building
			arrow.try_function = try_building
		"sink":
			arrow.validate_function = validate_sink
			arrow.try_function = try_sink
		"emerge":
			arrow.validate_function = validate_emerge
			arrow.try_function = try_emerge
		"mark":
			arrow.validate_function = validate_mark
			arrow.try_function = try_mark
		_:
			Utils.log("Unknown active effect: %s" % arrow.effect.target)
			arrow.queue_free()
	
	self.add_child(new_canvas_layer)
	new_canvas_layer.add_child(arrow)


func use_card(cardView):
	var cards_playable_per_turn = self.game.human.compute("cards_playable_per_turn")
	Utils.log("Cards Playable per turn: %s" % cards_playable_per_turn)
	if cards_playable_per_turn != -1 and self.game.human.resources.cards_played >= cards_playable_per_turn:
		messenger.set_message("You cannot play any more cards this turn.")
		return
	self.used_card = cardView
	cardView.highlight(true)
	
	Utils.log("Card %s used" % cardView.card.name)
	var play_powers = cardView.card.effects.filter(func(e): return e.type == Effect.Type.Power)
	if play_powers.size() > 0:
		create_arrow(cardView)
	else:
		self.card_used(cardView)

	
func card_used(cv):
	for effect in cv.card.effects.filter(func(e): return e.type != Effect.Type.Power):
		await Effects.add(effect)
	self.game.human.resources.faith -= cv.card.cost
	self.update_faith_player()
	self.used_card = null
	self.game.human.resources.cards_played += 1
	Effects.trigger(Effect.Trigger.CardPlayed)
	if self.over:
		return
	if cv.card.exhaust:
		self.deck.exhaust(cv)
	else:
		self.deck.discard(cv)
	
	

func closest_player_tile_coords():
	var closest_player_tile = Constants.NULL_COORDS
	var closest_tile_distance = 100000
	var camera_tile = self.world.local_to_map(self.world.camera.position)
	for region in self.world.regions:
		if self.world.regions[region].data.team == self.game.human.team:
			var center_tile = self.world.regions[region].center_tile()
			var distance = Utils.distance(center_tile, camera_tile)
			if distance < closest_tile_distance:
				closest_player_tile = center_tile
				closest_tile_distance = distance
	return closest_player_tile
	

func check_win_condition():
	for player in self.game.players:
		if not regions_left(player.team) and not player.eliminated:
			player.eliminated = true
			messenger.set_message(Constants.TEAM_NAMES[player.team] + " has been wiped from the island!")
	if self.game.human.eliminated:
		Info.lost = true
		self.over = true
		await SceneTransition.change_scene(SceneTransition.SCENE_REWARD)
	elif self.game.players.filter(func(p): return !p.eliminated).size() < 2:
		self.over = true
		await SceneTransition.change_scene(SceneTransition.SCENE_REWARD)

func clear_selected_region():
	if selected_region != null:
		self.world.regions[selected_region].set_selected(false)
		self.selected_region = null
	
func handle_move(clicked_region):
	mouse_state = MouseState.Move
	if self.game.current_player.is_bot:
		clear_mouse_state()
		return
	if clicked_region.data.is_used:
		clear_mouse_state()
		return
	if selected_region != null and clicked_region.data.id == selected_region:
		clear_mouse_state()
		return
	if selected_region == null:
		if clicked_region.data.team == self.game.human.team:
			self.selected_region = clicked_region.data.id
			self.world.regions[selected_region].set_selected(true)
			Sfx.play(Sfx.Track.Select)
	else:
		if clicked_region.data.id not in self.world.adjacent_regions(self.selected_region):
			clear_mouse_state()
			return
		else:
			self.world.regions[selected_region].update()
			clicked_region.update()
			if self.world.regions[selected_region].data.units > 1:
				var move = Action.new(Action.Type.Move, {"from": selected_region, "to": clicked_region.data.id, "team": self.game.human.team} )
				await self.apply_action(move)
			else:
				messenger.set_message("My lord, we cannot leave this region undefended!")
			clear_mouse_state()

func play_global_turn():
	await self.game.next_turn()
	world.path_lengths.clear()
	world.path_lengths = world.all_path_lengths()
	while self.game.current_player != self.game.human:
		self.messenger.set_message(Constants.TEAM_NAMES[self.game.current_player.team] + " is making their move...")
		generate_units(self.game.current_player.team)
		await play_turn()
		self.game.next_player()

	await self.world.sink_marked()
	await check_win_condition()
	await self.world.mark_tiles(self.game.global_turn)
	

func prepare_turn():
	self.generate_units(self.game.human.team)
	self.game.human.resources.faith = self.game.human.compute("faith_per_turn") + self.world.tiles.values().filter(func(t): return t.data.team == self.game.human.team and t.data.building == Constants.Building.Temple).size()
	self.game.human.resources.cards_played = 0
	self.update_faith_player()
	await self.deck.draw_multiple(self.game.human.compute("cards_per_turn"))
	self.deck.update_faith(self.game.human.resources.faith)

func play_turn():
	var playing = true
	while playing:
		var thread = Thread.new()
		Utils.log("PLAYER %s TURN" % self.game.current_player.team)
		thread.start(self.game.current_player.bot.play_turn.bind(self.world))
		while thread.is_alive():
			await Utils.wait(0.1)
		# var bot_actions = thread.wait_to_finish()
		var bot_actions = self.game.current_player.bot.play_turn(self.world) ## use for debugging
		for bot_action in bot_actions:
			if bot_action.type == Action.Type.None:
				playing = false
				break
			await apply_action(bot_action)
			await Utils.wait(Settings.turn_time)
	self.world.clear_regions_used()
	await Utils.wait(Settings.turn_time)

func regions_left(team):
	for region in world.regions:
		if world.regions[region].data.team == team:
			return true
	return false

func generate_units(team):
	for region in world.regions.keys().filter(func(r): return world.regions[r].data.team == team):
		world.regions[region].generate_units(self.game.player_from_team(team).compute("units_per_tile"))

func apply_action(action : Action):
	if over:
		return
	self.game.actions_history.append(action)
	match action.type:
		Action.Type.Move:
			await self.world.move_units(action.data.from, action.data.to, action.data.team)
		Action.Type.Sink:
			await self.world.sink_tiles(action.data.value)
			Effects.trigger(Effect.Trigger.TileSunk)
		Action.Type.Emerge:
			for tile_array in action.data.value:
				await self.world.emerge_tiles(tile_array)
			Effects.trigger(Effect.Trigger.TileEmerged)
		Action.Type.Sacrifice:
			sacrifice_region(action.data.region, game.get_current_player().team)
			Effects.trigger(Effect.Trigger.RegionSacrificed)
		Action.Type.Build:
			self.world.tiles[action.data.coords].set_building(action.data.building)
			Effects.trigger(Effect.Trigger.BuildingBuilt)
		Action.Type.Reinforce:
			self.world.regions[action.data.region].data.units += action.data.value
			if self.world.regions[action.data.region].data.team == Constants.NULL_TEAM:
				self.world.regions[action.data.region].set_team(self.game.human.team)
			self.world.regions[action.data.region].update()
			Effects.trigger(Effect.Trigger.RegionReinforced)
		Action.Type.Faith:
			self.game.current_player.resources.faith = action.data.value
			if !game.current_player.is_bot:
				self.update_faith_player()
		Action.Type.RandomDiscard:
			self.deck.discard_random(action.data.value)
		Action.Type.Draw:
			self.deck.draw_multiple(action.data.value)
		Action.Type.Renewal:
			for region_id in action.data.value:
				self.world.regions[region_id].set_used(false)
				self.world.regions[region_id].update()
			messenger.set_message("Regions of %s have been renewed!" % Constants.TEAM_NAMES[game.current_player.team])
		Action.Type.Treason:
			for treason in action.data.value:
				self.world.regions[treason.region].set_team(treason.new_team)
				self.world.regions[treason.region].update()
			messenger.set_message("Regions of %s have defected to the enemy!" % Constants.TEAM_NAMES[game.current_player.team])
		Action.Type.Mark:
			for mark in action.data.value:
				self.world.tiles[mark].mark()
		Action.Type.None:
			pass
		_:
			Utils.log("Unknown action: %s" % action)
	await check_win_condition()

func update_faith_player():
	self.deck.update_faith(self.game.human.resources.faith)
	self.faith_label.set_text(str(self.game.human.resources.faith) + "/" + str(self.game.human.resources.faith_per_turn))

func load_map(map_regions):
	self.world.clear_island()
	self.world.load_regions(map_regions)
	for region in self.world.regions.values():
		if region.data.team != self.game.human.team:
			if region.data.team != Constants.NULL_TEAM:
				region.generate_units(self.game.player_from_team(region.data.team).compute("units_per_tile"))
			else:
				region.generate_units(self.game.global.compute("initial_neutral_units"))

func fast_forward(val):
	Settings.skip(val)
	self.world.camera.skip(val)
	self.fastForwardButton.button_pressed = val

			
func sacrifice_region(region_id, team_id):
	if self.world.regions[region_id].data.team != team_id:
		Utils.log("ERROR: Trying to sacrifice region %s, but it belongs to team %s" % [region_id, self.world.regions[region_id].data.team])
	# self.add_faith(team_id, self.world.regions[region_id].sacrifice())
	self.world.regions[region_id].sacrifice()
	#self.add_cards(2)
	messenger.set_message("%s has sacrificed a region's inhabitants to the gods!" % Constants.TEAM_NAMES[team_id])
		

func _on_fast_forward_button_toggled(button_pressed:bool):
	fast_forward(button_pressed)
