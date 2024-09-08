extends RefCounted
class_name Global

var resources: Dictionary = DEFAULT_RESOURCES.duplicate()

const DEFAULT_RESOURCES = {
	"initial_neutral_units": 1,
	}

func compute(r : String):
	var res = self.resources.duplicate()
	for effect in Effects.global_effects.filter(func(e): return e.target == r):
		var expression = Expression.new()
		expression.parse(effect.value, res.keys())
		var result = expression.execute(res.values())
		res[effect.target] = result
	Utils.log("Global has " + str(res[r]) + " " + r + " computed from " + str(self.resources[r]) + " base.")
	return res[r]
