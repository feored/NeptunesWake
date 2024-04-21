extends Node

signal apply_active(e : Effect)
signal triggered

var get_current_player : Callable

var effects: Dictionary = {}
var global_effects = []

var targets = {
	"flat_reinforce_bonus": ["reinforcements"],
	"flat_sink_bonus": ["sink", "sink_random_tiles"]
}


func init(players, get_current_player_func):
	self.effects.clear()
	self.get_current_player = get_current_player_func
	for p in players:
		self.effects[p] = []

func add(e : Effect, p : Player = null):
	if p == null:
		p = self.get_current_player.call()
	Utils.log("Adding effect: " + str(e) + " for player " + str(p))
	if e.type == Effect.Type.Active and e.active_trigger == Effect.Trigger.Instant:
		self.apply_active.emit(e)
	else:
		self.effects[p].push_back(e)
		#self.list_changed(e)
	self.triggered.emit()
	
func add_global(e : Effect):
	if e.type == Effect.Type.Active and e.active_trigger == Effect.Trigger.Instant:
		self.apply_active.emit(e)
	else:
		self.global_effects.push_back(e)


func trigger(t: Effect.Trigger):
	var call_actives = func(arr):
		for e in arr:
			if e.active_trigger == t:
				Utils.log("Triggering effect: " + str(e))
				self.apply_active.emit(e)
	var reduce_duration = func(arr, trig = false):
		for e in arr:
			e.duration -= 1
			if e.duration <= 0:
				arr.erase(e)
				# if trig:
				# 	self.list_changed(e)

	Utils.log("Triggered: " + str(Effect.Trigger.keys()[t]))
	var p = self.get_current_player.call()

	var to_trigger = self.effects[p].filter(func (e): return e.active_trigger == t)
	call_actives.call(to_trigger)
	
	var to_trigger_global = self.global_effects.filter(func (e): return e.active_trigger == t)
	call_actives.call(to_trigger_global)

	var duration_affected = self.effects[p].filter(func (e): return e.duration_trigger == t)
	reduce_duration.call(duration_affected)

	var global_duration_affected = self.global_effects.filter(func (e): return e.duration_trigger == t)
	reduce_duration.call(global_duration_affected)

	self.triggered.emit()

# # when the list of the current player changes, notify the deck to recompute
# # effect values and update display. This should send the resource that was affected
# # so that only card related to that effect are recomputed
# func list_changed(e):
# 	self.triggered.emit(e)