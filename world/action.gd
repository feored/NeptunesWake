extends RefCounted
class_name Action

enum Type {
	None,
	Move,
	Sink,
	Emerge,
	Sacrifice,
	Reinforce,
	Build,
	Mark,
	RandomDiscard,
	Draw,
	Faith,
	Treason,
	Renewal
}

var type: Type = Action.Type.None
var data = {}


func _init(init_type: Type, init_data: Dictionary):
	self.type = init_type
	self.data = init_data


func clone():
	return Action.new(self.type, self.data.duplicate())


func _to_string():
	return "Action: " + Action.Type.keys()[self.type] + " : " + str(self.data)
